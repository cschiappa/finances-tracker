//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by Cristina on 27/08/2023.
//

import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject var transactionListVM = TransactionListViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(transactionListVM)
        }
    }
}
