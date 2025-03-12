//
//  File.swift
//  FSKit-macOS
//
//  Created by Bean John on 9/30/24.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

public extension FileManager {
	
	/// Function to allow user to select a file or directory
	@MainActor
	static func selectFile(
		rootUrl: URL? = nil,
		dialogTitle: String,
		canSelectFiles: Bool = true,
		canSelectDirectories: Bool = true,
		allowedContentTypes: [UTType]? = nil,
		showHiddenFiles: Bool = false,
		allowMultipleSelection: Bool = false,
		persistPermissions: Bool = true
	) throws -> [URL] {
		// Set panel properties
		let dialog = NSOpenPanel()
		if let rootUrl = rootUrl {
			dialog.directoryURL = rootUrl
		}
		dialog.title = dialogTitle
		dialog.message = dialogTitle
		dialog.showsResizeIndicator = false
		dialog.canCreateDirectories = true
		dialog.canChooseFiles = canSelectFiles
		dialog.canChooseDirectories = canSelectDirectories
		dialog.showsHiddenFiles = showHiddenFiles
		dialog.allowsMultipleSelection = allowMultipleSelection
		if let allowedContentTypes = allowedContentTypes {
			dialog.allowedContentTypes = allowedContentTypes
			dialog.allowsOtherFileTypes = false
		}
		// If user clicked OK
		if dialog.runModal() == .OK {
			// Persist permissions if requested
			if persistPermissions {
				for url in dialog.urls {
					Bookmarks.shared.saveToBookmark(url: url)
				}
			}
			// Return urls
			return dialog.urls
		}
		throw SelectionError.noSelection
	}
	
	/// Function to create a directory
	static func createDirectory(
		at url: URL,
		withIntermediateDirectories: Bool = true
	) {
		if !url.fileExists {
			try? FileManager.default.createDirectory(
				at: url,
				withIntermediateDirectories: true
			)
		}
	}
	
	/// Function to delete a file or directory
	static func removeItem(at url: URL) {
		if url.fileExists {
			try? FileManager.default.removeItem(at: url)
		}
	}
	
	/// Function to move a file
	@MainActor
	static func moveItem(
		from source: URL,
		to destination: URL,
		replacing: Bool = false,
		promptBeforeReplace: Bool = false
	) {
		// If file already exists
		if destination.fileExists {
			// If should prompt
			if promptBeforeReplace {
				// Prompt user
				let filename: String = source.lastPathComponent
				let promptText: String = "\(filename) already exists. Do you want to replace it?"
				// Run modal
				if !presentConfirmationModal(text: promptText) {
					// If cancelled, exit
					return
				}
			} else {
				// If no prompt, and not replacing, return
				if !replacing {
					return
				} else {
					// If is replacing, delete original copy
					FileManager.removeItem(at: destination)
				}
			}
		}
		// Move item
		do {
			try FileManager.default.moveItem(
				at: source,
				to: destination
			)
		} catch {
			print("error: ", error)
		}
	}
	
	/// Function to copy a file
	@MainActor
	static func copyItem(
		from source: URL,
		to destination: URL,
		replacing: Bool = false,
		promptBeforeReplace: Bool = false
	) {
		// If file already exists
		if destination.fileExists {
			// If should prompt
			if promptBeforeReplace {
				// Prompt user
				let filename: String = source.lastPathComponent
				let promptText: String = "\(filename) already exists. Do you want to replace it?"
				// Run modal
				if !presentConfirmationModal(text: promptText) {
					// If cancelled, exit
					return
				}
			} else {
				// If no prompt, and not replacing, return
				if !replacing {
					return
				}
			}
		}
		// Move item
		do {
			try FileManager.default.copyItem(
				at: source,
				to: destination
			)
		} catch {
			print("error: ", error)
		}
	}
	
	/// Function to show file or directory in Finder
	@MainActor
	static func showItemInFinder(url: URL) {
		// If directory
		if url.hasDirectoryPath {
			NSWorkspace.shared.selectFile(
				nil,
				inFileViewerRootedAtPath: url.posixPath
			)
		} else {
			// Else, open and select
			NSWorkspace.shared.activateFileViewerSelecting(
				[url]
			)
		}
	}
	
	/// Function to share files
	@MainActor
	static func shareFiles(
		urls: [URL],
		sharingService: NSSharingService.Name = .sendViaAirDrop
	) throws {
		// Throw error if any file is non-existent
		if urls.map({
			$0.fileExists
		}).contains(false) {
			throw FileError.fileMissing
		}
		// Start NSSharingService
		guard let service: NSSharingService = NSSharingService(
			named: sharingService
		) else {
			// Throw error for failure to establish service
			throw SharingError.serviceInitFailed
		}
		// Open window to share file
		if service.canPerform(withItems: urls) {
			service.perform(withItems: urls)
		}  else {
			throw SharingError.serviceError
		}
	}
	
	
	
	/// Function to present confirmation modal
	@MainActor
	static private func presentConfirmationModal(
		text: String,
		confirmText: String = "Yes",
		cancelText: String = "No"
	) -> Bool {
		// Prompt user
		let nsAlert: NSAlert = NSAlert()
		nsAlert.messageText = text
		nsAlert.addButton(withTitle: cancelText)
		nsAlert.addButton(withTitle: confirmText)
		// If "no"
		if nsAlert.runModal() == .alertFirstButtonReturn {
			return false
		}
		// Else, return "yes"
		return true
	}
	
}

public extension FileManager {
	
	enum SelectionError: Error {
		case noSelection
	}
	
	enum FileError: Error {
		case fileMissing
	}
	
	enum SharingError: Error {
		case serviceInitFailed
		case serviceError
	}
	
}
