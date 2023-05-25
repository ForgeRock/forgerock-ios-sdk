//
//  StatusView.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//
import SwiftUI

struct StatusView: View {
    @EnvironmentObject var statusViewModel: StatusViewModel
    
    var body: some View {
        Text(statusViewModel.status.statusDescription)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(statusViewModel.color)
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
            .environmentObject(StatusViewModel())
    }
}
