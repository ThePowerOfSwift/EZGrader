//
//  ViewController.swift
//  EZ Grader
//
//  Copyright © 2018 RIT. All rights reserved.
//

import PDFKit
import MobileCoreServices
import os.log

class SelectPDFDocumentsToGradeViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        allowsDocumentCreation = false
        allowsPickingMultipleItems = true
    }


    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // Create a new document. The function is not being used in the app
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
    }
    
    // Import a document. This function is not being used in the app
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        os_log("==> Imported A Document from %@ to %@.",
               log: OSLog.default,
               type: .debug,
               sourceURL.path,
               destinationURL.path)
        
        presentDocument(at: [destinationURL])
    }
    
    // This function is called if the selected document cannot be imported. THis function is not being used in the application
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        
        let alert = UIAlertController(
            title: "Unable to Import Document",
            message: "An error occurred while trying to import a document: \(error?.localizedDescription ?? "No Description")",
            preferredStyle: .alert)
        
        let action = UIAlertAction(
            title: "OK",
            style: .cancel,
            handler: nil)
        
        alert.addAction(action)
        
        controller.present(alert, animated: true, completion: nil)
    }
    
    // This function is called when the user selects one or more documents
    func documentBrowser(_ controller: UIDocumentBrowserViewController,
                         didPickDocumentURLs documentURLs: [URL]) {

        presentDocument(at: documentURLs)

    }
    
    // Present the selected documents
    func presentDocument(at documentURLs: [URL]) {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        
        let storyBoardVC = storyBoard.instantiateViewController(withIdentifier: "gradePDFDocumentsViewController")
        
        guard let gradePDFDocumentsVC = storyBoardVC as? GradePDFDocumentsViewController else {
            return
        }
        
        gradePDFDocumentsVC.loadViewIfNeeded()
        
        // Convert the URLs to EZPDFDocument instances
        let allDocuments = documentURLs.map {
            EZPDFDocument(fileURL: $0)
        }
       
        gradePDFDocumentsVC.allSelectedDocuments = allDocuments
       
        openAll(allDocuments: allDocuments, first: 0, max: allDocuments.count, destinationVC: gradePDFDocumentsVC)

    }

    
    
    // Open all the selected documents and present the GradePdfDocumentViewController once done.
    func openAll(allDocuments: [EZPDFDocument], first: Int, max: Int, destinationVC: GradePDFDocumentsViewController) {
        
        if first < max {
            allDocuments[first].open { [weak self] (success) in
                if success {
                    if first+1 == max {
                        self?.present(destinationVC, animated: true, completion: nil)
                    } else {
                        self?.openAll(allDocuments: allDocuments, first: first+1, max: max, destinationVC: destinationVC)
                    }
                    
                }
            }
        }
    }
    
}
