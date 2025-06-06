//
//  UniversalScraper.swift
//  Lunr
//
//  Created by Lwin Oo on 6/5/25.
//

import Foundation
import SwiftSoup

struct ScrapedResult {
    let title: String
    let description: String
    let bodyText: String
}

final class UniversalScraper {
    static func scrape(urlString: String, completion: @escaping (ScrapedResult?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            do {
                let doc: Document = try SwiftSoup.parse(html)
                let title = try doc.title()
                let description = try doc.select("meta[name=description]").first()?.attr("content") ?? ""
                let bodyText = try doc.body()?.text() ?? ""

                let result = ScrapedResult(
                    title: title,
                    description: description,
                    bodyText: String(bodyText.prefix(3000)) // Truncate to stay under LLM limits
                )

                completion(result)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}

