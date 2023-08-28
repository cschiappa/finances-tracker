//
//  TransactionListViewModel.swift
//  ExpenseTracker
//
//  Created by Cristina on 28/08/2023.
//

import Foundation
import Combine
import Collections

typealias TransactionGroup = OrderedDictionary<String, [Transaction]>
typealias TransactionPrefixSum = [(String, Double)]

final class TransactionListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        getTransactions()
    }
    
    func getTransactions() {
        // Check if the URL is valid
        guard let url = URL(string: "https://designcode.io/data/transactions.json") else {
            print("Invalid url")
            return
        }
        
        // Create a data task publisher for the specified URL
        URLSession.shared.dataTaskPublisher(for: url)
            // Try to transform the received data and response
            .tryMap { (data, response) -> Data in
                // Check the HTTP response status code
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    // Print response info and throw an error
                    dump(response)
                    throw URLError(.badServerResponse)
                }
                
                // If status code is OK, return the received data
                return data
            }
        
            // Decode the received data into an array of Transaction objects
            .decode(type: [Transaction].self, decoder: JSONDecoder())
            
            // Switch to the main thread for UI updates
            .receive(on: DispatchQueue.main)
            
            // Subscribe to the publisher and handle events
            .sink { completion in
                switch completion {
                case .failure(let error):
                    // Print error message if network or decoding fails
                    print("Error fetching transactions", error.localizedDescription)
                case .finished:
                    // Print message when fetching is finished successfully
                    print("Finished fetching transactions")
                }
            } receiveValue: { [weak self] result in
                // Update transactions array with fetched data
                self?.transactions = result
                
            }
            // Store the subscription to keep it alive
            .store(in: &cancellables)
    }
    
    func groupTransactionsByMonth() -> TransactionGroup{
        guard !transactions.isEmpty else{ return [:] }
        
        let groupedTransactions = TransactionGroup(grouping: transactions) {$0.month}
        
        return groupedTransactions
    }
    
    
    func accumulateTransactions() -> TransactionPrefixSum{
        print("accumulateTransactions")
        guard !transactions.isEmpty else{ return []}
        
        let today = "2/17/2022".dateParsed()
        let dateInterval = Calendar.current.dateInterval(of: .month, for: today)!
        print("dateIntercal", dateInterval)
        
        var sum: Double = .zero
        var cumulativeSum = TransactionPrefixSum()
        
        for date in stride(from: dateInterval.start, to: today, by: 60 * 60 * 24){
            let dailyExpenses = transactions.filter({ $0.dateParsed == date && $0.isExpense })
            let dailyTotal = dailyExpenses.reduce(0) { $0 - $1.signedAmount}
            
            sum += dailyTotal
            sum = sum.roundedTo2Digits()
            cumulativeSum.append((date.formatted(), sum))
            print(date.formatted(), "dailyTotal:", dailyTotal, "sum", sum)
        }
        
        return cumulativeSum
    }
}

