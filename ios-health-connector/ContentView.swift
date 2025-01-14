//
//  ContentView.swift
//  ios-health-connector
//
//  Created by Oluwatobi Ijose on 1/14/25.
//

import SwiftUI

struct ContentView: View {
    @State private var statusMessage: String = "Press Sync to load workouts."
    
    var body: some View {
        VStack {
            Text("Health Sync")
                .font(.largeTitle)
                .padding()
            
            Text(statusMessage)
                .font(.body)
                .padding()
            
            Button(action: syncData) {
                Text("Sync Data")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
    }
    
    private func syncData() {
        // Request authorization and fetch data
        HealthKitManager.shared.requestAuthorization { success, error in
            if let error = error {
                print("Authorization error: \(error)")
                return
            }
            if success {
                HealthKitManager.shared.fetchWorkouts { workouts, error in
                    if let error = error {
                        print("Error fetching workouts: \(error)")
                        return
                    }
                    DispatchQueue.main.async {
                        if let workouts = workouts {
                            // Send workouts to the cloud (AWS)
                            let url = URL(string: "http://192.168.1.81:8000")!
                            HealthKitManager.shared.uploadWorkout(workouts: workouts, url: url)
                        } else {
                            print("No workouts found")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    statusMessage = "Authorization failed: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
