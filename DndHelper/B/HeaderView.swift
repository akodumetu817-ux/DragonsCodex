//
//  HeaderView.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Text("Home")
                .font(.custom(AppFontName.aclonicaRegular, size: 30))
                .foregroundColor(.primaryText)
            Spacer()
        }
        .padding()
        .background(Color.sectionHeaderBackground)
        .cornerRadius(10)
    }
}
