//
//  EZPDFDocument.swift
//  EZ Grader
//
//  Created by Akshay Kalbhor on 10/19/18.
//  Copyright © 2018 RIT. All rights reserved.
//

//
//  EZPDFDocument.swift
//  Document Browser
//
//  Created by Akshay Kalbhor on 10/18/18.
//  Copyright © 2018 Apple. All rights reserved.
//

/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 A document that manages UTF8 text files.
 */

import UIKit
import PDFKit
import os.log

enum EZPDFDocumentError: Error {
    case unableToParseText
    case unableToEncodeText
}

protocol EZPDFDocumentDelegate: class {
    func textDocumentEnableEditing(_ doc: EZPDFDocument)
    func textDocumentDisableEditing(_ doc: EZPDFDocument)
    func textDocumentUpdateContent(_ doc: EZPDFDocument)
    func textDocumentTransferBegan(_ doc: EZPDFDocument)
    func textDocumentTransferEnded(_ doc: EZPDFDocument)
    func textDocumentSaveFailed(_ doc: EZPDFDocument)
}

/// - Tag: TextDocument
class EZPDFDocument: UIDocument {
    
    public var text = "" {
        didSet {
            // Notify the delegate when the text changes.
            if let currentDelegate = delegate {
                //currentDelegate.textDocumentUpdateContent(self)
            }
        }
    }
    
    public var innerPDFDocument: PDFDocument!
    
    //public var innerPDFDocument: GradedPDFDocument!
    
    public weak var delegate: EZPDFDocumentDelegate?
    public var loadProgress = Progress(totalUnitCount: 10)
    
    private var docStateObserver: Any?
    private var transfering: Bool = false
    
    override init(fileURL url: URL) {
        
        docStateObserver = nil
        super.init(fileURL: url)
        
        //innerPDFDocument = PDFDocument(url: url)
       
        innerPDFDocument = PDFDocument(url: url)
                
        let notificationCenter = NotificationCenter.default
        let mainQueue = OperationQueue.main
        
        docStateObserver = notificationCenter.addObserver(
            forName: .UIDocumentStateChanged,
            object: self,
            queue: mainQueue) { [weak self](_) in
                
                guard let doc = self else {
                    return
                }
                
                doc.updateDocumentState()
        }
        
        
    }
    
    init() {
        
        let tempDir = FileManager.default.temporaryDirectory
        
        let url = tempDir.appendingPathComponent("MyTextDoc.txt")
        
        super.init(fileURL: url)
    }
    
    deinit {
        if let docObserver = docStateObserver {
            NotificationCenter.default.removeObserver(docObserver)
        }
    }
    
    override func contents(forType typeName: String) throws -> Any {
        
       guard let data = innerPDFDocument.dataRepresentation() else {
            throw EZPDFDocumentError.unableToEncodeText
        }
        

        return data as Any
    }
        
        
        
        
        //        guard let data = text.data(using: .utf8) else {
        //            throw TextDocumentError.unableToEncodeText
        //        }
        //
        //        os_log("==> Text Data Saved", log: OSLog.default, type: .debug)
    
    
    //    // Uncomment to simulate slow, incremental loading.
    //    override func read(from url: URL) throws {
    //
    //        let group = DispatchGroup()
    //        let backgroundQueue = DispatchQueue(label: "Background Queue", qos: .background)
    //        let theProgress = loadProgress
    //
    //        // Simulate a slow load.
    //        for i in 1..<loadProgress.totalUnitCount {
    //            group.enter()
    //            backgroundQueue.async {
    //                Thread.sleep(forTimeInterval: 0.25)
    //                theProgress.completedUnitCount = i
    //                group.leave()
    //            }
    //        }
    //
    //        // Wait until all the parts have loaded, then call super.
    //        group.wait()
    //        try super.read(from: url)
    //
    //        // Mark the progress as complete
    //        loadProgress.completedUnitCount = loadProgress.totalUnitCount
    
    //    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        guard let data = contents as? Data else {
            // This would be a developer error.
            fatalError("*** \(contents) is not an instance of NSData.***")
        }
        
        guard let newPDFDocument = PDFDocument(data: data) else {
            throw EZPDFDocumentError.unableToParseText
        }

        innerPDFDocument = newPDFDocument
        
    }
    
    
    //        guard let newText = String(data: data, encoding: .utf8) else {
    //            throw TextDocumentError.unableToParseText
    //        }
    
    // MARK: - Private Methods
    
    //        // Mark the progress as complete
    //        loadProgress.completedUnitCount = loadProgress.totalUnitCount
    
    //os_log("==> Text Data Loaded", log: OSLog.default, type: .debug)
    //text = newText
    
    private func updateDocumentState() {
        
        if documentState == .normal {
            os_log("=> Document entered normal state", log: OSLog.default, type: .debug)
            if let currentDelegate = delegate {
                currentDelegate.textDocumentEnableEditing(self)
            }
        }
        
        if documentState.contains(.closed) {
            os_log("=> Document has closed", log: OSLog.default, type: .debug)
            if let currentDelegate = delegate {
                currentDelegate.textDocumentDisableEditing(self)
            }
        }
        
        if documentState.contains(.editingDisabled) {
            os_log("=> Document's editing is disabled", log: OSLog.default, type: .debug)
            if let currentDelegate = delegate {
                currentDelegate.textDocumentDisableEditing(self)
            }
        }
        
        if documentState.contains(.inConflict) {
            os_log("=> A docuent conflict was detected", log: OSLog.default, type: .debug)
            resolveDocumentConflict()
        }
        
        if documentState.contains(.savingError) {
            if let currentDelegate = delegate {
                currentDelegate.textDocumentSaveFailed(self)
            }
        }
        
        handleDocStateForTransfers()
    }
    
    private func handleDocStateForTransfers() {
        if transfering {
            // If we're in the middle of a transfer, check to see if the transfer has ended.
            if !documentState.contains(.progressAvailable) {
                transfering = false
                if let currentDelegate = delegate {
                    currentDelegate.textDocumentTransferEnded(self)
                }
            }
        } else {
            // If we're not in the middle of a transfer, check to see if a transfer has started.
            if documentState.contains(.progressAvailable) {
                os_log("=> A transfer is in progress", log: OSLog.default, type: .debug)
                
                if let currentDelegate = delegate {
                    currentDelegate.textDocumentTransferBegan(self)
                    transfering = true
                }
            }
        }
    }
    
    private func resolveDocumentConflict() {
        
        // To accept the current version, remove the other versions,
        // and resolve all the unresolved versions.
        
        do {
            try NSFileVersion.removeOtherVersionsOfItem(at: fileURL)
            
            if let conflictingVersions = NSFileVersion.unresolvedConflictVersionsOfItem(at: fileURL) {
                for version in conflictingVersions {
                    version.isResolved = true
                }
            }
        } catch let error {
            os_log("*** Error: %@ ***", log: OSLog.default, type: .error, error.localizedDescription)
        }
    }
}


