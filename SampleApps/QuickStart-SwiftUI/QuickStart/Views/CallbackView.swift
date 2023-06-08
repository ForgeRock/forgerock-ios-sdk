//
//  CallbackView.swift
//  QuickStart
//
// Copyright (c) 2023 ForgeRock. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import SwiftUI

struct CallbackView: View {
    @Binding var callbackViewModel: CallbackViewModel
    
    var body: some View {
        HStack {
            Text(callbackViewModel.name)
            if callbackViewModel.isSecret {
                SecureField(callbackViewModel.name, text: $callbackViewModel.value)
            } else {
                TextField(callbackViewModel.name, text: $callbackViewModel.value)
            }
        }.padding()
    }
}

struct CallbackView_Previews: PreviewProvider {
    static var previews: some View {
        CallbackView(callbackViewModel: .constant(CallbackViewModel(name: "Name", value: "Value")))
    }
}
