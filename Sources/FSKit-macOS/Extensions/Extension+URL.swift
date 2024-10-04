//
//  Extension+URL.swift
//  FSKit-macOS
//
//  Created by Bean John on 9/28/24.
//

import Foundation
import AppKit
import QuickLookThumbnailing

public extension URL {
	
	/// Computed property returning path to URL
	var posixPath: String {
		if #available(macOS 13.0, *) {
			return self.path(percentEncoded: false)
		} else {
			return self.path.removingPercentEncoding!
		}
	}
	
	/// Function to check if directory contains URL
	func dirContains(_ url: URL) -> Bool {
		// Perform checks
		let fileExists: Bool = FileManager.default.fileExists(atPath: url.posixPath)
		let dirContains: Bool = url.posixPath.hasPrefix(self.posixPath)
		return fileExists && dirContains
	}
	
	/// Computed property returning items in directory
	var contents: [URL]? {
		// Return nil if URL is not directory
		if self.hasDirectoryPath {
			// Use directory enumerator for better performance
			let files: [URL] = FileManager.default.enumerator(
				at: self,
				includingPropertiesForKeys: nil
			)?.allObjects as? [URL] ?? []
			return files
		} else {
			return nil
		}
	}
	
	/// Computed property returning whether a directory is blank
	var isEmpty: Bool? {
		return self.contents?.isEmpty
	}
	
	/// Computed property returning the most recent date of modification for a file
	var lastModified: Date? {
		do {
			let attributes: [FileAttributeKey:Any] = try FileManager.default.attributesOfItem(atPath: self.posixPath)
			return attributes[FileAttributeKey.modificationDate] as? Date
		} catch {
			return nil
		}
	}
	
	/// Computed property returning whether file exists
	var fileExists: Bool {
		return FileManager.default.fileExists(
			atPath: self.posixPath
		)
	}
	
	/// Computed property returning name of a volume
	var volumeName: String {
		(try? resourceValues(forKeys: [.volumeNameKey]))?.volumeName ?? "null"
	}
	
	/// Computed property returning total capacity of a volume
	var volumeTotalCapacity: Int {
		(try? resourceValues(forKeys: [.volumeTotalCapacityKey]))?.volumeTotalCapacity ?? 0
	}
	
	/// Computed property returning total capacity of a volume for important usage
	var volumeAvailableCapacityForImportantUsage: Int64 {
		(try? resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]))?.volumeAvailableCapacityForImportantUsage ?? 0
	}
	
	/// Computed property returning total capacity of a volume for not too important usage
	var volumeAvailableCapacityForOpportunisticUsage: Int64 {
		(try? resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey]))?.volumeAvailableCapacityForOpportunisticUsage ?? 0
	}
	
	/// Function to get thumbnail of file
	@MainActor
	func thumbnail(
		size: CGSize,
		scale: CGFloat,
		completion: @escaping (CGImage) -> Void
	) async {
		let request = QLThumbnailGenerator.Request(
			fileAt: self,
			size: size,
			scale: scale,
			representationTypes: .lowQualityThumbnail
		)
		QLThumbnailGenerator.shared.generateRepresentations(
			for: request
		) { (thumbnail, type, error) in
			DispatchQueue.main.async {
				if thumbnail == nil || error != nil {
					// Handle the error case gracefully.
					let nsImage: NSImage = NSWorkspace.shared.icon(
						forFile: self.posixPath
					)
					var rect: NSRect = NSRect(
						origin: CGPoint(x: 0, y: 0),
						size: nsImage.size
					)
					let result: CGImage = nsImage.cgImage(
						forProposedRect: &rect,
						context: NSGraphicsContext.current,
						hints: nil
					)!
					completion(result)
				} else {
					// Display the thumbnail that you created.
					let result: CGImage = thumbnail!.cgImage
					completion(result)
				}
			}
		}
	}
	
	/// Computed property returning `true` if hidden (invisible) or `false` if not hidden (visible)
	var isHidden: Bool {
		return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
	}
	
}
