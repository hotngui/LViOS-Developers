//
//  ContentView.swift
//  Simple
//
//  Created by Joey Jarosz on 2/11/20.
//  Copyright © 2020 hot-n-GUI, LLC. All rights reserved.
//

import SwiftUI

struct ContentView: View {
   var body: some View {
      let restaurants = DataStore.getRestaurants()

      return List(restaurants) { restaurant in
           RestaurantRow(restaurant: restaurant)
      }
   }
}

struct RestaurantRow: View {
    var restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(restaurant.name)")
            Text("\(restaurant.address)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

