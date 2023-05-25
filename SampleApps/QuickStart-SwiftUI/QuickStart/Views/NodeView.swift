//
//  NodeView.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth

struct NodeView: View {
    @EnvironmentObject var statusViewModel: StatusViewModel
    @StateObject var nodeViewModel: NodeViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Text(nodeViewModel.journeyName)
            .font(.title)
            .padding()
        List {
            ForEach($nodeViewModel.callbackViewModels) { $callbackViewModel in
                CallbackView(callbackViewModel: $callbackViewModel)
            }
        }.onAppear {
            nodeViewModel.statusViewModel = statusViewModel
            nodeViewModel.parseNode()
        }
        
        Spacer()
        
        Button("Next") {
            nodeViewModel.submitNode()
        }
        .foregroundColor(.white)
        .font(Font.body.bold())
        .padding(10)
        .padding(.horizontal, 20)
        .background(.blue)
        .cornerRadius(10)
        .padding()
        .onChange(of: nodeViewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .navigationDestination(isPresented: $nodeViewModel.showNodeView) {
            NodeView(nodeViewModel: nodeViewModel)
        }
    }
    
}

struct NodeView_Previews: PreviewProvider {
    static var previews: some View {
        NodeView(nodeViewModel: NodeViewModel())
    }
}
