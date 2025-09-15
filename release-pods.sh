#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Array of libraries to release in order of dependency
# First items should be the ones with no dependencies
LIBRARIES=("FRCore" "FRAuth" "FRDeviceBinding" "PingProtect" "FRCaptchaEnterprise" "FRUI" "FRProximity" "FRGoogleSignIn" "FRFacebookSignIn" "FRAuthenticator")

# Version being published for all libraries
VERSION="4.8.0"

# Maximum waiting time in seconds (60 minutes = 3600 seconds)
MAX_WAIT_TIME=3600
# Wait interval between retry attempts (in seconds)
WAIT_INTERVAL=180

# Function to check if a specific pod version is available on CocoaPods
check_pod_availability() {
  local pod_name=$1
  local version=$2
  local pod_info=$(pod trunk info $pod_name 2>/dev/null)

  # Check if the pod exists and the specific version is available
  if [[ $pod_info == *"$pod_name"* && $pod_info == *"$version"* ]]; then
    echo -e "${GREEN}Found version $version of $pod_name in registry${NC}"
    return 0  # Specific pod version is available
  else
    echo -e "${YELLOW}Version $version of $pod_name not found in registry${NC}"
    return 1  # Specific pod version is not available yet
  fi
}

# Function to lint pod with time-based retries
lint_pod_with_time_based_retries() {
  local lib=$1
  local elapsed_time=0
  local attempt=1

  while [[ $elapsed_time -lt $MAX_WAIT_TIME ]]; do
    echo -e "\n${CYAN}${BOLD}Linting $lib version $VERSION${NC}"
    echo -e "${CYAN}Attempt $attempt, elapsed time: $elapsed_time seconds of max $MAX_WAIT_TIME seconds${NC}"

    if pod spec lint "$lib.podspec" --allow-warnings --verbose; then
      echo -e "\n${GREEN}${BOLD}Linting successful for $lib${NC}"
      return 0
    else
      echo -e "\n${YELLOW}Linting failed for $lib. This could be due to dependencies not being fully available yet.${NC}"
      echo -e "${BLUE}Running 'pod repo update' and waiting $WAIT_INTERVAL seconds before retrying...${NC}"
      pod repo update

      # Update elapsed time and attempt counter
      elapsed_time=$((elapsed_time + WAIT_INTERVAL))
      attempt=$((attempt + 1))

      if [[ $elapsed_time -lt $MAX_WAIT_TIME ]]; then
        sleep $WAIT_INTERVAL
      else
        echo -e "${RED}${BOLD}ERROR: Linting failed for $lib after waiting for $MAX_WAIT_TIME seconds (maximum wait time reached)${NC}"
        return 1
      fi
    fi
  done

  return 1
}

# Main release process
echo -e "${MAGENTA}${BOLD}Starting CocoaPods Release Process${NC}"
echo -e "${MAGENTA}${BOLD}===============================${NC}"

for lib in "${LIBRARIES[@]}"; do
  echo -e "\n${MAGENTA}${BOLD}Processing library: $lib${NC}"
  echo -e "${MAGENTA}===============================${NC}"

  # Step 1: Lint the pod with time-based retries
  if ! lint_pod_with_time_based_retries "$lib"; then
    echo -e "${RED}${BOLD}ERROR: Linting ultimately failed for $lib after maximum wait time${NC}"
    exit 1
  fi

  # Step 2: Push the pod with allow-warnings and verbose flags
  echo -e "\n${CYAN}${BOLD}Pushing $lib version $VERSION to trunk...${NC}"
  if ! pod trunk push "$lib.podspec" --allow-warnings --verbose; then
    echo -e "${RED}${BOLD}ERROR: Trunk push failed for $lib${NC}"
    exit 1
  fi

  echo -e "\n${GREEN}${BOLD}Successfully published $lib version $VERSION${NC}"

  # Step 3: Verify the pod is visible in the registry
  # This is just a verification step, not a full dependency check
  local registry_check_time=0
  while [[ $registry_check_time -lt 300 ]]; do  # Check for up to 5 minutes
    if check_pod_availability "$lib" "$VERSION"; then
      echo -e "${GREEN}$lib version $VERSION is visible in the CocoaPods registry${NC}"
      break
    else
      echo -e "${YELLOW}Waiting for $lib version $VERSION to appear in registry... (elapsed: $registry_check_time seconds)${NC}"
      sleep $WAIT_INTERVAL
      registry_check_time=$((registry_check_time + WAIT_INTERVAL))
    fi
  done

  if [[ $registry_check_time -ge 300 ]]; then
    echo -e "${YELLOW}${BOLD}WARNING: $lib version $VERSION is not visible in registry after 5 minutes${NC}"
    echo -e "${YELLOW}Continuing anyway as the next dependency linting phase will retry...${NC}"
  fi

  echo -e "\n${GREEN}${BOLD}Completed processing for $lib${NC}"
  echo -e "${MAGENTA}===============================${NC}"
done

echo -e "\n${GREEN}${BOLD}All libraries have been successfully released!${NC}"