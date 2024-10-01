//
//  Bookmarks.swift
//  FSKit-macOS
//
//  Created by Bean John on 10/1/24.
//

import Foundation

/// NOTE: Before use, 2 entitlements need to be added
/// <key>com.apple.security.files.user-selected.read-write</key>
/// <true/>
/// <key>com.apple.security.files.bookmarks.app-scope</key>
/// <true/>

/// Class to persist file access permissions
final public class Bookmarks: NSObject, NSSecureCoding {
	
	@MainActor static public let shared: Bookmarks = Bookmarks.loadAndInit()
	
	static public let supportsSecureCoding: Bool = true

	required public init?(coder: NSCoder) {
		self.data = coder.decodeObject(
			of: [NSDictionary.self, NSData.self, NSURL.self]
			, forKey: "bookmarksData"
		) as? [URL: Data] ?? [:]
	}
	
	required init(data: [URL: Data]) {
		self.data = data
	}
	
	deinit {
		self.save()
	}

	public func encode(with coder: NSCoder) {
		coder.encode(self.data, forKey: "bookmarksData")
	}
	
	var data: [URL: Data] = [URL: Data]()
	
	/// Function to persist access permissions
	public func saveToBookmark(url: URL) {
		do {
			// Get data
			let bookmarkData: Data = try url.bookmarkData(
				options: NSURL.BookmarkCreationOptions.withSecurityScope,
				includingResourceValuesForKeys: nil,
				relativeTo: nil
			)
			// Save
			self.data[url] = bookmarkData
			save()
		} catch {
			print ("Error storing bookmark for file \(url.lastPathComponent)")
		}
	}
	
	/// Function to save all bookmark data
	private func save() {
		// Get location
		let datastoreUrl: URL = Self.getBookmarkDatastoreUrl()
		// Convert to raw data
		if let data: Data = try? NSKeyedArchiver.archivedData(
			withRootObject: self.data,
			requiringSecureCoding: true
		) {
			// Save to disk
			try? data.write(to: datastoreUrl, options: .atomic)
		}
	}
	
	/// Function to load all bookmark data
	private static func loadAndInit() -> Bookmarks {
		let datastoreUrl: URL = Self.getBookmarkDatastoreUrl()
		// Load data
		let nsData: NSData? = NSData(contentsOf: datastoreUrl)
		// Fall back if failed
		guard let nsData: NSData = nsData else {
			print("Failed to load bookmarks")
			return Bookmarks(
				data: [URL: Data]()
			)
		}
		if let bookmarks = try? NSKeyedUnarchiver.unarchivedObject(
			ofClass: Self.self,
			from: nsData as Data
		) {
			print("Loaded \(bookmarks.data.count) bookmarks")
			for bookmark in bookmarks.data {
				let _ = bookmarks.restorePermissions(url: bookmark.key)
			}
			return bookmarks
		} else {
			// Fall back
			print("Failed to load bookmarks")
			return Bookmarks(
				data: [URL: Data]()
			)
		}
	}
	
	/// Static function returning bookmark datastore url
	private static func getBookmarkDatastoreUrl() -> URL {
		return FileManager.default
			.urls(
				for: .documentDirectory,
				in: .userDomainMask
			)
			.first!
			.appendingPathComponent(
				"Bookmarks.dict"
			)
	}
	
	/// Function to resume access to a file, returning boolean to show if succeeded
	public func restorePermissions(url: URL) -> Bool {
		// Load bookmark data
		guard let data: Data = self.data[url] else {
			print("No privileges for file \(url.lastPathComponent)")
			return false
		}
		// Start access
		let restoredUrl: URL?
		var isStale: Bool = false
		do {
			restoredUrl = try URL.init(
				resolvingBookmarkData: data,
				options: NSURL.BookmarkResolutionOptions.withSecurityScope,
				relativeTo: nil,
				bookmarkDataIsStale: &isStale
			)
		} catch {
			print("Error restoring bookmark for file \(url.lastPathComponent)")
			restoredUrl = nil
			return false
		}
		// Start access
		if let url = restoredUrl {
			if isStale {
				print("URL \(url.absoluteString) is stale")
			} else {
				let result: Bool = url.startAccessingSecurityScopedResource()
				if !result {
					print("Failed to access file \(url.lastPathComponent)")
				}
				return result
			}
		}
		// If fall through, return false
		return false
	}
	
}
