//
//  NetworkService.swift
//  Melbe
//
//  Created by D K on 07.05.2025.
//

import Foundation

enum AppConstants {
    static let dndAPIBaseURL = "https://www.dnd5eapi.co"
}

import Foundation

enum NetworkError: Error {
    case badURL
    case requestFailed(Error)
    case decodingError(Error)
    case invalidResponse
    case unknown
}

class APIService {
    static let shared = APIService()
    private let baseURLString = AppConstants.dndAPIBaseURL
    private let monstersListPath = "/api/monsters"

    private init() {}

    func fetchAllMonstersList() async -> Result<[MonsterListItem], NetworkError> {
        guard let url = URL(string: baseURLString + monstersListPath) else {
            print("APIService Error: Invalid URL for monster list - \(baseURLString + monstersListPath)")
            return .failure(.badURL)
        }
        
        print("APIService: Fetching monster list from: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("APIService Error: Invalid HTTP response for monster list. Status: \(statusCode). Response: \(response)")
                return .failure(.invalidResponse)
            }
            
            let decodedResponse = try JSONDecoder().decode(MonsterListResponse.self, from: data)
            guard let monsterItems = decodedResponse.results else {
                print("APIService Error: Monster list results are nil after decoding.")
                return .failure(.decodingError(NSError(domain: "APIService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Monster list results are nil"])))
            }
            print("APIService: Successfully fetched \(monsterItems.count) monster list items.")
            return .success(monsterItems)
        } catch let error as DecodingError {
            print("APIService Error: Decoding monster list failed - \(error.localizedDescription)")
            self.printDecodingErrorDetails(error)
            return .failure(.decodingError(error))
        } catch {
            print("APIService Error: Request for monster list failed - \(error.localizedDescription)")
            return .failure(.requestFailed(error))
        }
    }

    func fetchMonsterDetail(from relativePath: String) async -> Result<MonsterDetail, NetworkError> {
        guard !relativePath.isEmpty else {
            print("APIService Error: Relative path for monster detail is empty.")
            return .failure(.badURL)
        }

        
        let cleanedBaseURL = baseURLString.hasSuffix("/") ? String(baseURLString.dropLast()) : baseURLString
        let cleanedRelativePath = relativePath.hasPrefix("/") ? relativePath : "/" + relativePath
        
        guard let fullURL = URL(string: cleanedBaseURL + cleanedRelativePath) else {
            print("APIService Error: Could not construct full URL for monster detail from base: \(cleanedBaseURL) and relative: \(cleanedRelativePath)")
            return .failure(.badURL)
        }
        
        print("APIService: Fetching monster detail from: \(fullURL)")

        do {
            let (data, response) = try await URLSession.shared.data(from: fullURL)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("APIService Error: Invalid HTTP response for monster detail (\(fullURL)). Status: \(statusCode). Response: \(response)")
                return .failure(.invalidResponse)
            }
            
            let decoder = JSONDecoder()
            let monsterDetail = try decoder.decode(MonsterDetail.self, from: data)
            print("APIService: Successfully fetched detail for: \(monsterDetail.name ?? "Unknown Monster") (\(fullURL))")
            return .success(monsterDetail)

        } catch let error as DecodingError {
            print("APIService Error: Decoding monster detail (\(fullURL)) failed - \(error.localizedDescription)")
            self.printDecodingErrorDetails(error) // Используем хелпер для подробного вывода
            return .failure(.decodingError(error))
        } catch {
            print("APIService Error: Request for monster detail (\(fullURL)) failed - \(error.localizedDescription)")
            return .failure(.requestFailed(error))
        }
    }

    private func printDecodingErrorDetails(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("  Type Mismatch: '\(type)' for key(s) '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. DebugDescription: \(context.debugDescription)")
        case .valueNotFound(let value, let context):
            print("  Value Not Found: '\(value)' for key(s) '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. DebugDescription: \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            print("  Key Not Found: '\(key.stringValue)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. DebugDescription: \(context.debugDescription)")
        case .dataCorrupted(let context):
            print("  Data Corrupted: at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'. DebugDescription: \(context.debugDescription)")
        @unknown default:
            print("  Unknown decoding error: \(error.localizedDescription)")
        }
       
    }
}
