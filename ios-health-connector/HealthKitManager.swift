//
//  HealthKitManager.swift
//  ios-health-connector
//
//  Created by Oluwatobi Ijose on 1/14/25.
//

import HealthKit
import Foundation

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // Request authorization to access HealthKit data
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, NSError(domain: "com.example.healthsync", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"]))
            return
        }
        
        let readTypes: Set<HKObjectType> = [HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: nil, read: readTypes, completion: completion)
    }
    
    // Fetch workouts from HealthKit
    func fetchWorkouts(completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let workoutType = HKWorkoutType.workoutType()
        let query = HKSampleQuery(sampleType: workoutType, predicate: nil, limit: 0, sortDescriptors: nil) { _, results, error in
            if let error = error {
                print("Error fetching workouts: \(error)")
            }
            completion(results as? [HKWorkout], error)
        }
        healthStore.execute(query)
    }

    func uploadWorkout(workouts: [HKWorkout], url: URL) {
        let workoutData = workouts.map { workout -> [String: Any] in
            let caloriesBurned = workout.statistics(for: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            
            return [
                "type": HKWorkoutActivityType(rawValue: workout.workoutActivityType.rawValue) ?? workout.workoutActivityType.rawValue,
                "duration": workout.duration,
                "calories": caloriesBurned,
                "date": ISO8601DateFormatter().string(from: workout.startDate)
            ]
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let body = ["workouts": workoutData]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            let task = URLSession.shared.dataTask(with: request) { _, _, error in
                if let error = error {
                    print("Error uploading data: \(error)")
                } else {
                    print("Data uploaded successfully!")
                }
            }
            task.resume()
        } catch {
            print("Error serializing data: \(error)")
        }
    }
    
}
