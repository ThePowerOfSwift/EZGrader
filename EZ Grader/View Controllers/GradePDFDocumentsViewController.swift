//
//  GradePDFsViewController.swift
//  EZ Grader
//
//  Copyright © 2018 RIT. All rights reserved.
//

import PDFKit

// The diffferent modes for the application

enum EZGraderMode {
    
    case viewPDFDocuments
    // The default mode which you enter, when you chose a document, can scroll up and down
    case freeHandAnnotate
    // The mode for annotating the document which you have selected
    case eraseFreeHandAnnotation
    // The mode for erasing annotations
    case textAnnotate
    // The mode for adding text to the PDF document
    case addGrade
    
    
}

class GradePDFDocumentsViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // The view which displays the color of the annotations
    @IBOutlet weak var colorPreview: UIView!
    
    // The three sliders to choose a color for the annotations
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    
    // The function called when the user changes the slider value
    @IBAction func sliderChanged(_ sender: Any) {
        let newColor = UIColor.init(red: CGFloat(redSlider.value), green: CGFloat(greenSlider.value), blue: CGFloat(blueSlider.value), alpha: 1.0)
        self.colorPreview.backgroundColor = newColor
        generalAnnotationColor = newColor
    }
    
    // The view which contains the sliders and the colorPreview
    @IBOutlet weak var drawingOptionsView: UIView!
    
    // The function which hides/displays the drawingOptionsView
    @IBAction func showDrawingOptions(_ sender: Any) {
        self.drawingOptionsView.isHidden = false
    }
    
    // The color used for annotations
    var generalAnnotationColor: UIColor = UIColor.purple
    
    // The reference to the perPageButton
    @IBOutlet weak var perPageButton: UIButton!
  
    // The mainStackView has all the annotation buttons and the clear, CSV and close buttons
    @IBOutlet weak var mainStackView: UIStackView!
    
    // The doneStackView has the edit and done button
    @IBOutlet weak var doneStackView: UIStackView!
    
    // The common parent view for main and done stack views
    @IBOutlet weak var newView: UIView!
    
    // The font size used in the app
    let appFontSize: CGFloat = 30

    // The current mode of the app
    var ezGraderMode: EZGraderMode?
    
    // UIBezierPath for free hand annotation
    var currentFreeHandPDFAnnotationBezierPath: UIBezierPath!
    
    // The PDFAnnotation formed from the UIBezierPath
    var currentFreeHandPDFAnnotation: PDFAnnotation!
    
    // The free hand annotation PDFPage
    var currentFreeHandPDFAnnotationPDFPage: PDFPage!
    
    // Bool which indicates if the user has left the currentPage while annotating
    var leftCurrentPageWhenFreeHandAnnotating: Bool!
    
    // Stores the number of pages in a PDF document
    var numberOfPagesPerPDFDocument: Int!
    
     // The combined PDF Document. All the pages from all the selected documents are combined
    var combinedPDFDocument: PDFDocument!
   
    // Stores all the selected documents
    var allSelectedDocuments: [EZPDFDocument]!
    
    // Bool which denotes if the per PDFPage mode is active
    var isPerPDFPageMode: Bool!
    
    // The bool is used while freeHand annotating
    var isDot: Bool!
    
    // The default button Tint color
    var appDefaultButtonTintColor: UIColor!
 
    
    //var pdfDocumentURLs: [URL] = []
    // The array of pdf document URLs
    
    // The array contains file names of all the selected documents
    var pdfDocumentFileNames: [String] = []
    
    
    // The pdfView is the main view of the app which displays the combined pdf document
    @IBOutlet weak var pdfView: PDFView!
    
    // Activity indicator to tell the user that a task is being carried out
    @IBOutlet var uiActivityIndicatorView: UIActivityIndicatorView!
    
    
    
    // Toggles the viewMode between perPage and perDocument
    @IBAction func perPageButtonClicked(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        
        if self.isPerPDFPageMode {
            self.viewPerPDFDocument()
        } else {
            self.viewPerPDFPage()
        }
    }
    
    // Enter the freeHand annotation mode
    @IBAction func freeHandAnnotate(_ freeHandAnnotateButton: UIBarButtonItem) -> Void {
        
        // 1. Create a new UIBezierPath instance and assign it to the property currentFreeHandPDFAnnotationBezierPath
        self.currentFreeHandPDFAnnotationBezierPath = UIBezierPath()

        // 2. Disable user interaction for the pdfView
        self.pdfView.isUserInteractionEnabled = false

        // 3. Change the property ezGraderMode to freeHandAnnotate
        self.ezGraderMode = EZGraderMode.freeHandAnnotate

        // Update the top bar to indicate that the user has selected the freeHandAnnotate tool
        self.updateTopBar()
    }
    
    
    // Enter the erase free hand annotation mode
    @IBAction func eraseFreeHandAnnotation(_ eraseFreeHandAnnotationButton: UIBarButtonItem) -> Void {
        
        // 1. Change the property ezGraderMode to eraseFreeHandAnnotation
        self.ezGraderMode = .eraseFreeHandAnnotation
        // 2. Update the navigation bar to indicate that the app is in the eraseFreeHandAnnotation mode
        self.updateTopBar()
    }
    
    // Enter the text annotation mode
    @IBAction func textAnnotate(_ textAnnotateButton: UIBarButtonItem) -> Void {
        
        // 1. Disable user interaction for the pdfView
        self.pdfView.isUserInteractionEnabled = false

        // 2. Change the value of the ezGraderMode property to textAnnotate
        self.ezGraderMode = .textAnnotate

        // 3. Update the navigationBar to indicate that the application is in textAnnotate mode
        self.updateTopBar()
    }
    
    // Go back to the selectPDFDocumentsViewControllwe
    @IBAction func goBack(_ sender: Any) {
        // 1. Dismiss the current view controller
        dismiss(animated: true) {}
        
    }
    
    
    // Enter the add grade annotation mode
    @IBAction func addGrade(_ addGradeButton: UIBarButtonItem) -> Void {
        
        // 1. Disable user interaction for the pdfView
        self.pdfView.isUserInteractionEnabled = false

        // 2. Change the ezGrader mode to addGrade
        self.ezGraderMode = .addGrade

        // 3. Update the navigation bar to indicate that the application is in addGrade mode
        self.updateTopBar()
    }
    
    
    
    
    // Generate a CSV file and present the user with options to send it via email or save it to Files
    @IBAction func getCSVAndSend() {
        
        var allPDFDocumentGrades: [ String: [ Int: [String] ] ] = [:]
        
        if (self.isPerPDFPageMode) {
            
            let numberOfPDFDocuments: Int = self.combinedPDFDocument.pageCount / self.numberOfPagesPerPDFDocument
            
            for pdfDocumentIndex: Int in 0...numberOfPDFDocuments - 1 {
                for pdfDocumentPageIndex: Int in 0...self.numberOfPagesPerPDFDocument - 1 {
                    
                    if let pdfPage = self.combinedPDFDocument.page(at: (pdfDocumentPageIndex * numberOfPDFDocuments + pdfDocumentIndex)) {
                        
                        self.updateGradesForPDFDocumentPage(pdfPage: pdfPage, allPDFDocumentGrades: &allPDFDocumentGrades, pdfDocumentIndex: pdfDocumentIndex, pdfDocumentPageIndex: pdfDocumentPageIndex)
                    }

                    

                }
            }
            
            
        } else {
            
            for pageIndex in 0..<self.combinedPDFDocument.pageCount {
                
                if let pdfPage = self.combinedPDFDocument.page(at: pageIndex) {
                    
                    let pdfDocumentIndex = pageIndex / self.numberOfPagesPerPDFDocument
                    
                    self.updateGradesForPDFDocumentPage(pdfPage: pdfPage, allPDFDocumentGrades: &allPDFDocumentGrades, pdfDocumentIndex: pdfDocumentIndex, pdfDocumentPageIndex: pageIndex % self.numberOfPagesPerPDFDocument)
                }
                
            }
        }
        
        self.writeOutGradesAsCSV(grades: allPDFDocumentGrades)
    }

    
    
    // Changes the layout of the combinedPDFDocument to display the selected documents per page
    func viewPerPDFPage() -> Void {
        
        // 1. If the current mode is 'PerPDFPage' then return immediately
        if self.isPerPDFPageMode == true {
            return
        }

        // 3. Set the 'isPerPDFPageMode' property to true
        self.isPerPDFPageMode = true

        // 6. Get the current page displayed by the PDFView
        let currentPDFPage: PDFPage = self.pdfView.currentPage!
        
        
        let perPDFPageCombinedPDFDocument = PDFDocument()

        let numberOfPDFDocuments: Int = self.combinedPDFDocument.pageCount / self.numberOfPagesPerPDFDocument

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            for pdfDocumentPageIndex: Int in 0...self.numberOfPagesPerPDFDocument - 1 {
                
                for pdfDocumentIndex: Int in 0...numberOfPDFDocuments - 1 {
                    
                    perPDFPageCombinedPDFDocument.insert(self.combinedPDFDocument.page(at: pdfDocumentIndex * self.numberOfPagesPerPDFDocument + pdfDocumentPageIndex)!, at: perPDFPageCombinedPDFDocument.pageCount)
                }
            }

            DispatchQueue.main.async {
                
                self.combinedPDFDocument = perPDFPageCombinedPDFDocument

                self.pdfView.document = self.combinedPDFDocument

                self.pdfView.go(to: currentPDFPage)
            }
        }
    }
    
    // The function is called just before the view appears on the screen. It is used for initial setup
    override func viewWillAppear(_ animated: Bool) {
        
        // Set document names and num of pages
        for document in self.allSelectedDocuments {
            let docFileName = document.fileURL.deletingPathExtension().lastPathComponent
            self.pdfDocumentFileNames.append(docFileName)
        }
        
        self.numberOfPagesPerPDFDocument = allSelectedDocuments[0].innerPDFDocument.pageCount
        
        // Create the combined document from all the selected documents
        
        self.combinedPDFDocument = PDFDocument()
        
        for document in allSelectedDocuments {
            for idx in 0..<self.numberOfPagesPerPDFDocument {
                if let page = document.innerPDFDocument.page(at: idx) {
                    self.combinedPDFDocument.insert(page, at: self.combinedPDFDocument.pageCount)
                }
            }
        }
        
        // Assign the combined document to the pdf view
        
        self.pdfView.document = self.combinedPDFDocument
    }
    
 
    // The function is called after the view disappears. It is used for cleanup
    override func viewDidDisappear(_ animated: Bool) {
        for document in self.allSelectedDocuments {
            document.close { (success) in
                print("CLOSED SUCCESSFULY: \(success)")
            }
        }
    }
    
    // Changes the layout of the combined document so that the selected documents are displayed per document.
    func viewPerPDFDocument() -> Void {
        
        if self.isPerPDFPageMode == false {
            return
        }

        self.isPerPDFPageMode = false

        let currentPDFPage: PDFPage = self.pdfView.currentPage!

        let perPDFDocumentCombinedPDFDocument = PDFDocument()

        let numberOfPDFDocuments: Int = self.combinedPDFDocument.pageCount / self.numberOfPagesPerPDFDocument

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            
            for pdfDocumentIndex: Int in 0...numberOfPDFDocuments - 1 {
                
                for pdfDocumentPageIndex: Int in 0...self.numberOfPagesPerPDFDocument - 1 {
                    
                    perPDFDocumentCombinedPDFDocument.insert(self.combinedPDFDocument.page(at: pdfDocumentPageIndex * numberOfPDFDocuments + pdfDocumentIndex)!, at: perPDFDocumentCombinedPDFDocument.pageCount)
                }
            }

            DispatchQueue.main.async {

                self.combinedPDFDocument = perPDFDocumentCombinedPDFDocument

                self.pdfView.document = self.combinedPDFDocument

                self.pdfView.go(to: currentPDFPage)
            }
        }
    }
    
    
    
    // THe function puts the applcation into default mode
    @IBAction func doneEditing(_ doneEditingButton: UIBarButtonItem) -> Void {
        
            if self.ezGraderMode == EZGraderMode.freeHandAnnotate {
                
                self.currentFreeHandPDFAnnotation = nil
                self.currentFreeHandPDFAnnotationPDFPage = nil
                self.leftCurrentPageWhenFreeHandAnnotating = false
            
            }

            self.pdfView.isUserInteractionEnabled = true
            self.drawingOptionsView.isHidden = true
            self.ezGraderMode = EZGraderMode.viewPDFDocuments

            self.updateTopBar()
    }
    
    
    
    
    // The function is called when the user taps on the screen.
    // It is used to edit text and grade annotations and to remove free hand annotations
    @IBAction func tap(_ uiTapGestureRecognizer: UITapGestureRecognizer) -> Void {
        
        
        if self.ezGraderMode == EZGraderMode.viewPDFDocuments || self.ezGraderMode == EZGraderMode.eraseFreeHandAnnotation {
            
            if uiTapGestureRecognizer.state == UIGestureRecognizerState.recognized {
                
                let tapViewCoordinate: CGPoint = uiTapGestureRecognizer.location(in: self.pdfView)
                let pdfPageAtTappedPosition: PDFPage = self.pdfView.page(for: tapViewCoordinate, nearest: true)!
                let tapPDFPageCoordinate: CGPoint = self.pdfView.convert(tapViewCoordinate, to: pdfPageAtTappedPosition)

                
                print("Tap: \(tapViewCoordinate)")
                print("TapPDFPage: \(tapPDFPageCoordinate)")
                
                
                if self.ezGraderMode == EZGraderMode.viewPDFDocuments {
                    //Filter annotations on the page to only return tapped freetext PDF annotations
                    let tappedFreeTextPDFAnnotations: [PDFAnnotation] = pdfPageAtTappedPosition.annotations.filter({ (pdfAnnotation: PDFAnnotation) -> Bool in
                        return pdfAnnotation.type! == PDFAnnotationSubtype.freeText.rawValue.replacingOccurrences(of: "/", with: "") && pdfAnnotation.bounds.contains(tapPDFPageCoordinate)
                    })

                    if tappedFreeTextPDFAnnotations.count > 0 {
                        let topTappedFreeTextPDFAnnotation: PDFAnnotation = tappedFreeTextPDFAnnotations[tappedFreeTextPDFAnnotations.count - 1]
                        if let username = topTappedFreeTextPDFAnnotation.userName {
                            if username == "TextAnnotation" {
                                self.showEditRemoveTextAnnotationDialog(tappedTextAnnotation: topTappedFreeTextPDFAnnotation)
                            }
                            if username == "GradeAnnotation" {
                                self.showEditRemoveGradeDialog(tappedGradeAnnotation: topTappedFreeTextPDFAnnotation)
                            }
                        }
                       
                    }
                
                } else {
                    
                    //Filter annotations on the page to only return tapped ink PDF annotations
                    let tappedInkPDFAnnotations: [PDFAnnotation] = pdfPageAtTappedPosition.annotations.filter({ (pdfAnnotation: PDFAnnotation) -> Bool in
                        
                        if pdfAnnotation.type! == PDFAnnotationSubtype.ink.rawValue.replacingOccurrences(of: "/", with: "") {
                            
                            if let s1 = pdfAnnotation.userName {
                                let boundsf = CGRectFromString(s1)
                                return boundsf.contains(tapPDFPageCoordinate)
                            }
                            return false
                        } else {
                            return false
                        }
                        
                    })

                    if tappedInkPDFAnnotations.count > 0 {
                        pdfPageAtTappedPosition.removeAnnotation(tappedInkPDFAnnotations[tappedInkPDFAnnotations.count - 1])
                        for document in allSelectedDocuments {
                            document.updateChangeCount(.done)
                        }
                    }
                }
            }
        }
    }
    
    // Hides the status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    // This method is called just after the view loads. It is used for inital setup.
    override func viewDidLoad() -> Void {
        super.viewDidLoad()
        
        self.isPerPDFPageMode = false
        self.pdfView.displayMode = PDFDisplayMode.singlePageContinuous
        self.pdfView.autoScales = true
        self.pdfView.frame = self.view.bounds
        self.pdfView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        self.pdfView.isUserInteractionEnabled = true
        self.ezGraderMode = EZGraderMode.viewPDFDocuments
        self.leftCurrentPageWhenFreeHandAnnotating = false
        self.doneStackView.alpha = 0.0
        self.mainStackView.alpha = 1.0

    }
    
    
    // This method is called when the screen first registers a touch
    // It is used to add a text/grade annotation and a freehand annotation
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        
        // This method is called when the user touches the screen
        self.currentFreeHandPDFAnnotationBezierPath = UIBezierPath()
        
        if self.ezGraderMode == EZGraderMode.freeHandAnnotate || self.ezGraderMode == EZGraderMode.textAnnotate ||
            
            // If the current mode is free hand / text annotate / add grade
            
            self.ezGraderMode == EZGraderMode.addGrade {
           
            // Get the first touch from the array
            
            if let touch: UITouch = touches.first {
                
                // Get the coordinate of the touch in the current view
                
                let touchViewCoordinate: CGPoint = touch.location(in: self.pdfView)
                
                // Get the correct PDFPage instance which the user has touched
                
                let pdfPageAtTouchedPosition: PDFPage = self.pdfView.page(for: touchViewCoordinate, nearest: true)!
                
                // Get the coordinate of the touch in the context of the correct PDFPage
                
                let touchPDFPageCoordinate: CGPoint = self.pdfView.convert(touchViewCoordinate, to: pdfPageAtTouchedPosition)

                
                let pdfDocumentPageIndexAtTouchedPosition: Int = self.combinedPDFDocument.index(for: pdfPageAtTouchedPosition)
                
                if self.ezGraderMode == EZGraderMode.freeHandAnnotate {
                    
                    if self.currentFreeHandPDFAnnotationPDFPage == nil {
                        
                        self.currentFreeHandPDFAnnotationPDFPage = pdfPageAtTouchedPosition
                    }

                    if pdfPageAtTouchedPosition == self.currentFreeHandPDFAnnotationPDFPage {
                        
                        self.currentFreeHandPDFAnnotationBezierPath.move(to: touchPDFPageCoordinate)

                        self.isDot = true
                    }
                
                } else if self.ezGraderMode == EZGraderMode.textAnnotate {
                    
                    self.showAddTextAnnotationDialog(touchPDFPageCoordinate: touchPDFPageCoordinate, pdfDocumentPageIndexAtTouchedPosition: pdfDocumentPageIndexAtTouchedPosition)
                
                } else if self.ezGraderMode == EZGraderMode.addGrade {
                    
                    self.showAddGradeDialog(touchPDFPageCoordinate: touchPDFPageCoordinate, pdfDocumentPageIndexAtTouchedPosition: pdfDocumentPageIndexAtTouchedPosition)
                }
            }
        }
    
    }
    
    
    // This method is called when a registered touch moves on the screen.
    //
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        
        if self.ezGraderMode == EZGraderMode.freeHandAnnotate {
            
            if let touch: UITouch = touches.first {
                
                // screen location converted to pdfView location
                let touchViewCoordinate: CGPoint = touch.location(in: self.pdfView)
                
                // get the pdf page which was touched
                let pdfPageAtTouchedPosition: PDFPage = self.pdfView.page(for: touchViewCoordinate, nearest: true)!

                // if pdf page is equal to current free hand annotation page continue
                if pdfPageAtTouchedPosition == self.currentFreeHandPDFAnnotationPDFPage {
                    
                    // get the location on the pdf page
                    let touchPDFPageCoordinate: CGPoint = self.pdfView.convert(touchViewCoordinate, to: pdfPageAtTouchedPosition)

                    // if left current page is false
                    if !self.leftCurrentPageWhenFreeHandAnnotating {
                        // add a line to the current bezier path
                        self.currentFreeHandPDFAnnotationBezierPath.addLine(to: touchPDFPageCoordinate)
                        // is dot is false
                        self.isDot = false
                    } else {
                        // has left current page, so start a new bezier path
                        self.currentFreeHandPDFAnnotationBezierPath.move(to: touchPDFPageCoordinate)

                        // is DOt is true
                        self.isDot = true

                        // left current page is false
                        self.leftCurrentPageWhenFreeHandAnnotating = false
                    }

                    // update the free hand annotation in the correct page
                    self.updateFreeHandPDFAnnotationInPDFDocument(pdfPageAtTouchedPosition: pdfPageAtTouchedPosition)
                } else {
                    
                    // as pdfpage is not equal to current free hand pdf annotation pdf page, left = true
                    self.leftCurrentPageWhenFreeHandAnnotating = true

                    // is dot is false
                    self.isDot = false
                }
            }
        }
    }
    
    // The method is called when a registered touch moves off the screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        
        
        self.currentFreeHandPDFAnnotation = nil
        self.currentFreeHandPDFAnnotationPDFPage = nil
        self.leftCurrentPageWhenFreeHandAnnotating = false
    
        if self.ezGraderMode == EZGraderMode.freeHandAnnotate && self.isDot {
            
            // Get the first touch
            if let touch: UITouch = touches.first {
                
                
                // Get the touch location in pdf view
                let touchViewCoordinate: CGPoint = touch.location(in: self.pdfView)
                
                
                // Corresponding page
                let pdfPageAtTouchedPosition: PDFPage = self.pdfView.page(for: touchViewCoordinate, nearest: true)!


                if pdfPageAtTouchedPosition == self.currentFreeHandPDFAnnotationPDFPage {
                    
                    
                    // get coordinate on pdf page
                    let touchPDFPageCoordinate: CGPoint = self.pdfView.convert(touchViewCoordinate, to: pdfPageAtTouchedPosition)

                    
                    // update the current free hand pdf annotation bezier path
                    self.currentFreeHandPDFAnnotationBezierPath.addLine(to: CGPoint(x: touchPDFPageCoordinate.x + 1, y: touchPDFPageCoordinate.y))
                    self.currentFreeHandPDFAnnotationBezierPath.addLine(to: CGPoint(x: touchPDFPageCoordinate.x + 1, y: touchPDFPageCoordinate.y + 1))
                    self.currentFreeHandPDFAnnotationBezierPath.addLine(to: CGPoint(x: touchPDFPageCoordinate.x, y: touchPDFPageCoordinate.y + 1))
                    self.currentFreeHandPDFAnnotationBezierPath.addLine(to: touchPDFPageCoordinate)

                    // update freehand annotation in pdf document
                    self.updateFreeHandPDFAnnotationInPDFDocument(pdfPageAtTouchedPosition: pdfPageAtTouchedPosition)
                
                }
            }
        }
    }
    
    // The method is used to update a free hand annotation
    private func updateFreeHandPDFAnnotationInPDFDocument(pdfPageAtTouchedPosition: PDFPage) -> Void {
        
        
        // Get the index number for the specified page
        let pdfDocumentPageIndexAtTouchedPosition = self.combinedPDFDocument.index(for: pdfPageAtTouchedPosition)

        if self.currentFreeHandPDFAnnotation != nil {
            // remove the annotation from the correct page
            self.combinedPDFDocument.page(at: pdfDocumentPageIndexAtTouchedPosition)?.removeAnnotation(self.currentFreeHandPDFAnnotation)
        }

        // create a new annotation
        let currentAnnotationPDFBorder: PDFBorder = PDFBorder()

        currentAnnotationPDFBorder.lineWidth = 2.0

        // customize the pdf annotation
        self.currentFreeHandPDFAnnotation = PDFAnnotation(bounds: pdfPageAtTouchedPosition.bounds(for: PDFDisplayBox.cropBox), forType: PDFAnnotationSubtype.ink, withProperties: nil)
        self.currentFreeHandPDFAnnotation.color = generalAnnotationColor
        self.currentFreeHandPDFAnnotation.add(self.currentFreeHandPDFAnnotationBezierPath)
        self.currentFreeHandPDFAnnotation.userName = NSStringFromCGRect(self.currentFreeHandPDFAnnotationBezierPath.bounds)
        self.currentFreeHandPDFAnnotation.border = currentAnnotationPDFBorder
        
        // add the actual annotation
        self.combinedPDFDocument.page(at: pdfDocumentPageIndexAtTouchedPosition)?.addAnnotation(self.currentFreeHandPDFAnnotation)
        
        for document in allSelectedDocuments {
            document.updateChangeCount(.done)
        }
    }
    
    
    // Update the grades for a particular page
    private func updateGradesForPDFDocumentPage(pdfPage: PDFPage, allPDFDocumentGrades: inout [String: [Int: [String]]], pdfDocumentIndex: Int, pdfDocumentPageIndex: Int) -> Void {
        
        //Filter annotations on the page to only return grade annotations
        let sortedPDFPageGrades: [String] = pdfPage.annotations.filter({ (pdfAnnotation: PDFAnnotation) -> Bool in
            
            if let username = pdfAnnotation.userName {
                return username == "GradeAnnotation"
            } else {
                return false
            }
        }).sorted(by: { (grade1PDFAnnotation: PDFAnnotation, grade2PDFAnnotation: PDFAnnotation) -> Bool in
            return self.pdfView.convert(grade1PDFAnnotation.bounds, from: pdfPage).maxY < self.pdfView.convert(grade2PDFAnnotation.bounds, from: pdfPage).maxY
        }).map({ (gradePDFAnnotation: PDFAnnotation) -> String in
            return gradePDFAnnotation.contents!
        })

        // Get all grade strings sorted from top to bottom
        if sortedPDFPageGrades.count > 0 {
            var currentPDFDocumentGrades: [Int: [String]] = allPDFDocumentGrades.keys.contains(self.pdfDocumentFileNames[pdfDocumentIndex]) ? allPDFDocumentGrades[self.pdfDocumentFileNames[pdfDocumentIndex]]! : [:]

            currentPDFDocumentGrades[pdfDocumentPageIndex + 1] = sortedPDFPageGrades

            allPDFDocumentGrades[self.pdfDocumentFileNames[pdfDocumentIndex]] = currentPDFDocumentGrades
        }
    }
    

    
    // Write the grades dictionary to a CSV file and present share options
    private func writeOutGradesAsCSV(grades: [String: [Int: [String]]]) -> Void {
            
        var csvFileContentsString: String = "Page Number,Question Number,Max Question Points"
            
        for pdfDocumentFileName: String in self.pdfDocumentFileNames {
            csvFileContentsString += ",\"\(pdfDocumentFileName)\""
        }
        

        csvFileContentsString += "\n"
        

        if grades.keys.count == 0 {
            csvFileContentsString += "No grades have been entered yet.\n"
        } else {
            

            let pdfDocumentPageNumbersHavingGradesSorted: [Int] = grades[self.pdfDocumentFileNames[0]]!.keys.sorted(by: { (pdfDocumentPage1Number: Int, pdfDocumentPage2Number: Int) -> Bool in
                return pdfDocumentPage1Number < pdfDocumentPage2Number
            })

            
            // question max points
            var pdfDocumentPageQuestionMaximumPoints: String
            // question max points earcned
            var pdfDocumentPageQuestionPointsEarned: String

            for pdfDocumentPageNumberHavingGrades: Int in pdfDocumentPageNumbersHavingGradesSorted {
                
                // iterate through the sorted page numbers
                for pdfDocumentPageQuestionNumber: Int in 1...(grades[self.pdfDocumentFileNames[0]]![pdfDocumentPageNumberHavingGrades]?.count)! {
                    
                    // itereate through the grades on a page
                    if pdfDocumentPageQuestionNumber == 1 {
                        
                        // add "Page no" to the csv file contents string
                        csvFileContentsString += "\"Page \(pdfDocumentPageNumberHavingGrades)\""
                    }

                    pdfDocumentPageQuestionMaximumPoints = grades[self.pdfDocumentFileNames[0]]![pdfDocumentPageNumberHavingGrades]![pdfDocumentPageQuestionNumber - 1].components(separatedBy: "/").map({ (gradeComponent: String) -> String in
                        return gradeComponent.trimmingCharacters(in: CharacterSet.whitespaces)
                    })[1]

                    // Ad question numbers, and max points to the csv
                    csvFileContentsString += ",\"Question \(pdfDocumentPageQuestionNumber)\",\"\(pdfDocumentPageQuestionMaximumPoints)\""

                    
                    // get the points earned
                    for pdfDocumentFileName: String in self.pdfDocumentFileNames {
                        pdfDocumentPageQuestionPointsEarned = grades[pdfDocumentFileName]![pdfDocumentPageNumberHavingGrades]![pdfDocumentPageQuestionNumber - 1].components(separatedBy: "/").map({ (gradeComponent: String) -> String in
                            return gradeComponent.trimmingCharacters(in: CharacterSet.whitespaces)
                        })[0]

                        csvFileContentsString += ",\"\(pdfDocumentPageQuestionPointsEarned)\""
                    }

                    csvFileContentsString += "\n"
                }
            }
        }

        let fileManager = FileManager.default
        
        do {
            if let gURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                try csvFileContentsString.write(to: gURL.appendingPathComponent("Grades.csv"), atomically: true, encoding: String.Encoding.utf8)
                let finalURL = gURL.appendingPathComponent("Grades.csv")
                let activityVC = UIActivityViewController(activityItems: [finalURL], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = self.view
                self.present(activityVC, animated: true, completion: nil)
               
            }
        } catch  {
            print("WRONG SOMETTHING LINE 1199")
        }
    }
    
    
    
    // Presents a dialog box so that the user can enter some text
    private func showAddTextAnnotationDialog(touchPDFPageCoordinate: CGPoint, pdfDocumentPageIndexAtTouchedPosition: Int) -> Void {
        
        let addTextAnnotationUIAlertController: UIAlertController = UIAlertController(title: "Add Text Annotation", message: "", preferredStyle: UIAlertControllerStyle.alert)

        
        // Add action
        let addTextAnnotationUIAlertAction: UIAlertAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (alert: UIAlertAction!) in
            let enteredText: String = (addTextAnnotationUIAlertController.textFields?[0].text)!
            let enteredTextSize: CGSize = self.getTextSize(text: enteredText + "  ")

            let textAnnotationFreeTextPDFAnnotation: PDFAnnotation = PDFAnnotation(bounds: CGRect(origin: touchPDFPageCoordinate, size: CGSize(width: enteredTextSize.width, height: enteredTextSize.height)), forType: PDFAnnotationSubtype.freeText, withProperties: nil)

            textAnnotationFreeTextPDFAnnotation.fontColor = self.generalAnnotationColor
            textAnnotationFreeTextPDFAnnotation.font = UIFont.systemFont(ofSize: self.appFontSize)
            textAnnotationFreeTextPDFAnnotation.color = UIColor.clear
            textAnnotationFreeTextPDFAnnotation.isReadOnly = true
            textAnnotationFreeTextPDFAnnotation.contents = enteredText
            textAnnotationFreeTextPDFAnnotation.userName = "TextAnnotation"
 
            self.combinedPDFDocument.page(at: pdfDocumentPageIndexAtTouchedPosition)?.addAnnotation(textAnnotationFreeTextPDFAnnotation)
            
            for document in self.allSelectedDocuments {
                document.updateChangeCount(.done)
            }
            
        }

        
        // Cancel action
        let cancelAddTextAnnotationUIAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction!) in }

        
        // Add text field
        addTextAnnotationUIAlertController.addTextField { (textAnnotationTextField: UITextField) in
            textAnnotationTextField.placeholder = "Text Annotation"
        }

        addTextAnnotationUIAlertController.addAction(addTextAnnotationUIAlertAction)
        addTextAnnotationUIAlertController.addAction(cancelAddTextAnnotationUIAlertAction)

        self.present(addTextAnnotationUIAlertController, animated: true, completion: nil)
    }
    
    
    // Presents the edit/remove dialog box for text annotations
    private func showEditRemoveTextAnnotationDialog(tappedTextAnnotation: PDFAnnotation) -> Void {
        
        let editRemoveTextAnnotationUIAlertController: UIAlertController = UIAlertController(title: "Edit/Remove Text Annotation", message: "", preferredStyle: UIAlertControllerStyle.alert)

        let editTextAnnotationUIAlertAction: UIAlertAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default) { (alert: UIAlertAction!) in
            
            
            
            let editedText: String = (editRemoveTextAnnotationUIAlertController.textFields?[0].text)!
           
            
            let editedTextSize: CGSize = self.getTextSize(text: editedText + "  ")

            
            let textAnnotationFreeTextPDFAnnotation: PDFAnnotation = PDFAnnotation(bounds: CGRect(origin: tappedTextAnnotation.bounds.origin, size: CGSize(width: editedTextSize.width, height: editedTextSize.height)), forType: PDFAnnotationSubtype.freeText, withProperties: nil)
            
            textAnnotationFreeTextPDFAnnotation.fontColor = self.generalAnnotationColor
            textAnnotationFreeTextPDFAnnotation.font = UIFont.systemFont(ofSize: self.appFontSize)
            textAnnotationFreeTextPDFAnnotation.color = UIColor.clear
            textAnnotationFreeTextPDFAnnotation.isReadOnly = true
            textAnnotationFreeTextPDFAnnotation.contents = editedText
            textAnnotationFreeTextPDFAnnotation.userName = "TextAnnotation"
            
            // REMOVE PREV ANNOTATION
            let page = tappedTextAnnotation.page!
            
            page.removeAnnotation(tappedTextAnnotation)
            
            // ADD NEW ONE
            page.addAnnotation(textAnnotationFreeTextPDFAnnotation)
            
            for document in self.allSelectedDocuments {
                document.updateChangeCount(.done)
            }
        }

        let removeTextAnnotationUIAlertAction: UIAlertAction = UIAlertAction(title: "Remove", style: UIAlertActionStyle.destructive) { (alert: UIAlertAction!) in
            tappedTextAnnotation.page?.removeAnnotation(tappedTextAnnotation)
            for document in self.allSelectedDocuments {
                document.updateChangeCount(.done)
            }
        }

        let cancelEditTextAnnotationUIAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction!) in }

        editRemoveTextAnnotationUIAlertController.addTextField { (textAnnotationTextField: UITextField) in
            textAnnotationTextField.placeholder = "Text Annotation"
            textAnnotationTextField.text = tappedTextAnnotation.contents
        }

        editRemoveTextAnnotationUIAlertController.addAction(editTextAnnotationUIAlertAction)
        editRemoveTextAnnotationUIAlertController.addAction(removeTextAnnotationUIAlertAction)
        editRemoveTextAnnotationUIAlertController.addAction(cancelEditTextAnnotationUIAlertAction)

        self.present(editRemoveTextAnnotationUIAlertController, animated: true, completion: nil)
    }
    

    // Presents an dialog box so that the user can enter a grade
    private func showAddGradeDialog(touchPDFPageCoordinate: CGPoint, pdfDocumentPageIndexAtTouchedPosition: Int) -> Void {
        
        let addGradeUIAlertController: UIAlertController = UIAlertController(title: "Add Grade", message: "", preferredStyle: UIAlertControllerStyle.alert)

        // Add grade action
        let addGradeUIAlertAction: UIAlertAction = UIAlertAction(title: "Add", style: UIAlertActionStyle.default) { (alert: UIAlertAction!) in
            
            // Add grade to all pdfs
            self.addGradeToAllPDFDocuments(pointsEarned: (addGradeUIAlertController.textFields?[0].text)!, maximumPoints: (addGradeUIAlertController.textFields?[1].text)!, touchPDFPageCoordinate: touchPDFPageCoordinate, pdfDocumentPageIndexAtTouchedPosition: pdfDocumentPageIndexAtTouchedPosition)
        }

        let cancelAddGradeUIAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction!) in }

        addGradeUIAlertController.addTextField { (pointsEarnedTextField: UITextField) in
            pointsEarnedTextField.placeholder = "Points Earned"
            pointsEarnedTextField.keyboardType = UIKeyboardType.decimalPad
        }

        addGradeUIAlertController.addTextField { (maximumPointsTextField: UITextField) in
            maximumPointsTextField.placeholder = "Maximum Points"
            maximumPointsTextField.keyboardType = UIKeyboardType.decimalPad
        }

        addGradeUIAlertController.addAction(addGradeUIAlertAction)
        addGradeUIAlertController.addAction(cancelAddGradeUIAlertAction)

        self.present(addGradeUIAlertController, animated: true, completion: nil)

    }
    
    
    // Shows a dialog box so that the user can edit/remove grade annotations
    private func showEditRemoveGradeDialog(tappedGradeAnnotation: PDFAnnotation) -> Void {
    
        
        let editRemoveGradeUIAlertController: UIAlertController = UIAlertController(title: "Edit/Remove Grade", message: "", preferredStyle: UIAlertControllerStyle.alert)

        
        // Edit action : change the contents of tapped grade annotation
        let editGradeUIAlertAction: UIAlertAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default) { (alert: UIAlertAction!) in
            
            let editedGradeText: String = (editRemoveGradeUIAlertController.textFields?[0].text)! + " / " + (editRemoveGradeUIAlertController.textFields?[1].text)!
            let editedGradeTextSize: CGSize = self.getTextSize(text: editedGradeText + "  ")


            let gradeFreeTextPDFAnnotation: PDFAnnotation = PDFAnnotation(bounds: CGRect(origin: tappedGradeAnnotation.bounds.origin, size: CGSize(width: editedGradeTextSize.width, height: editedGradeTextSize.height)), forType: PDFAnnotationSubtype.freeText, withProperties: nil)
            
            gradeFreeTextPDFAnnotation.fontColor = self.generalAnnotationColor
            gradeFreeTextPDFAnnotation.font = UIFont.systemFont(ofSize: self.appFontSize)
            gradeFreeTextPDFAnnotation.color = UIColor.clear
            gradeFreeTextPDFAnnotation.isReadOnly = true
            gradeFreeTextPDFAnnotation.contents = editedGradeText
            gradeFreeTextPDFAnnotation.userName = "GradeAnnotation"
            
            let page = tappedGradeAnnotation.page!
            
            page.removeAnnotation(tappedGradeAnnotation)
            page.addAnnotation(gradeFreeTextPDFAnnotation)
            
            
            for document in self.allSelectedDocuments {
                document.updateChangeCount(.done)
            }
            
        }

        
        // Remove action
        let removeGradeFromAllPDFDocumentsUIAlertAction: UIAlertAction = UIAlertAction(title: "Remove from All", style: UIAlertActionStyle.destructive) { (alert: UIAlertAction!) in
            
            let gradeAnnotations: [PDFAnnotation] = tappedGradeAnnotation.page!.annotations.filter({ (pdfAnnotation: PDFAnnotation) -> Bool in
                
                if let username = pdfAnnotation.userName {
                    return username == "GradeAnnotation"
                } else {
                    return false
                }
                
            })

            // Remove grade from all pdf documents
            self.removeGradeFromAllPDFDocuments(pdfDocumentPageIndexAtTappedPosition: self.combinedPDFDocument.index(for: tappedGradeAnnotation.page!), gradeAnnotationIndex: gradeAnnotations.index(of: tappedGradeAnnotation)!)
        }

        
        
        // Cancel action
        let cancelEditGradeUIAlertAction: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (alert: UIAlertAction!) in }

        
        let gradeComponents: [String] = tappedGradeAnnotation.contents!.components(separatedBy: "/").map({ (gradeComponent: String) -> String in
            return gradeComponent.trimmingCharacters(in: CharacterSet.whitespaces)
        })

        
        // Add the two text fields
        editRemoveGradeUIAlertController.addTextField { (pointsEarnedTextField: UITextField) in
            pointsEarnedTextField.placeholder = "Points Earned"
            pointsEarnedTextField.keyboardType = UIKeyboardType.decimalPad
            pointsEarnedTextField.text = gradeComponents[0]
        }

        editRemoveGradeUIAlertController.addTextField { (maximumPointsTextField: UITextField) in
            maximumPointsTextField.placeholder = "Maximum Points"
            maximumPointsTextField.keyboardType = UIKeyboardType.decimalPad
            maximumPointsTextField.isEnabled = false
            maximumPointsTextField.textColor = UIColor.gray
            maximumPointsTextField.text = gradeComponents[1]
        }

        editRemoveGradeUIAlertController.addAction(editGradeUIAlertAction)
        editRemoveGradeUIAlertController.addAction(removeGradeFromAllPDFDocumentsUIAlertAction)
        editRemoveGradeUIAlertController.addAction(cancelEditGradeUIAlertAction)

        self.present(editRemoveGradeUIAlertController, animated: true, completion: nil)
    }
    
    
    
    // The method adds a grade to all the pdf documents
    private func addGradeToAllPDFDocuments(pointsEarned: String, maximumPoints: String, touchPDFPageCoordinate: CGPoint, pdfDocumentPageIndexAtTouchedPosition: Int) -> Void {
    
        let gradeForCurrentPDFDocument: String = pointsEarned + " / " + maximumPoints
        
        let gradeForOtherPDFDocuments: String =  "? / " + maximumPoints
        
        if self.isPerPDFPageMode {
            let numberOfPDFDocuments: Int = self.combinedPDFDocument.pageCount / self.numberOfPagesPerPDFDocument
            
            let indexOfPDFDocumentPageOfFirstPDFDocument: Int = pdfDocumentPageIndexAtTouchedPosition - (pdfDocumentPageIndexAtTouchedPosition % numberOfPDFDocuments)
            
            for indexOfPDFDocumentPageToAddGradeTo: Int in indexOfPDFDocumentPageOfFirstPDFDocument...indexOfPDFDocumentPageOfFirstPDFDocument + numberOfPDFDocuments - 1 {
                self.combinedPDFDocument.page(at: indexOfPDFDocumentPageToAddGradeTo)?.addAnnotation(createGradeFreeTextAnnotation(gradeText: indexOfPDFDocumentPageToAddGradeTo == pdfDocumentPageIndexAtTouchedPosition ? gradeForCurrentPDFDocument : gradeForOtherPDFDocuments, touchPDFPageCoordinate: touchPDFPageCoordinate))
            }
        } else {
            for indexOfPDFDocumentPageToAddGradeTo: Int in stride(from: pdfDocumentPageIndexAtTouchedPosition %
                
                self.numberOfPagesPerPDFDocument, to:
                self.combinedPDFDocument.pageCount, by: self.numberOfPagesPerPDFDocument) {
                    
                    self.combinedPDFDocument.page(at: indexOfPDFDocumentPageToAddGradeTo)?.addAnnotation(createGradeFreeTextAnnotation(gradeText: indexOfPDFDocumentPageToAddGradeTo == pdfDocumentPageIndexAtTouchedPosition ? gradeForCurrentPDFDocument : gradeForOtherPDFDocuments, touchPDFPageCoordinate: touchPDFPageCoordinate))
                    
            }
        }
       
        
        for document in allSelectedDocuments {
            document.updateChangeCount(.done)
        }
            
    }
    

    
    // Removes a grade from all the pdf documents
    private func removeGradeFromAllPDFDocuments(pdfDocumentPageIndexAtTappedPosition: Int, gradeAnnotationIndex: Int) -> Void {
    
        
        if self.isPerPDFPageMode {
            
            let numberOfPDFDocuments: Int = self.combinedPDFDocument.pageCount / self.numberOfPagesPerPDFDocument
            
            // Get the index of the pdfpage for the first document
            
            let indexOfPDFDocumentPageOfFirstPDFDocument: Int = pdfDocumentPageIndexAtTappedPosition - (pdfDocumentPageIndexAtTappedPosition % numberOfPDFDocuments)
            
            // Remove from each page
            
            for indexOfPDFDocumentPageToRemoveGradeFrom: Int in indexOfPDFDocumentPageOfFirstPDFDocument...indexOfPDFDocumentPageOfFirstPDFDocument + numberOfPDFDocuments - 1 {
                
                self.removeGradeFromPDFDocument(indexOfPDFDocumentPageToRemoveGradeFrom: indexOfPDFDocumentPageToRemoveGradeFrom, gradeAnnotationIndex: gradeAnnotationIndex)
            }

        } else {
            
            for indexOfPDFDocumentPageToRemoveGradeFrom: Int in stride(from: pdfDocumentPageIndexAtTappedPosition % self.numberOfPagesPerPDFDocument, to: self.combinedPDFDocument.pageCount, by: self.numberOfPagesPerPDFDocument) {
                self.removeGradeFromPDFDocument(indexOfPDFDocumentPageToRemoveGradeFrom: indexOfPDFDocumentPageToRemoveGradeFrom, gradeAnnotationIndex: gradeAnnotationIndex)
            }
        }
        
        
        for document in allSelectedDocuments {
            document.updateChangeCount(.done)
        }
            
    }
    
    
    // Remove a grade from a pdf document
    private func removeGradeFromPDFDocument(indexOfPDFDocumentPageToRemoveGradeFrom: Int, gradeAnnotationIndex: Int) -> Void {

        if let gradeAnnotationToRemove = self.combinedPDFDocument.page(at: indexOfPDFDocumentPageToRemoveGradeFrom)?.annotations.filter ({
            if let username = $0.userName {
                return username == "GradeAnnotation"
            } else {
                return false
            }
        })[gradeAnnotationIndex] {
            self.combinedPDFDocument.page(at: indexOfPDFDocumentPageToRemoveGradeFrom)?.removeAnnotation(gradeAnnotationToRemove)
        }
    }

    
    
    // Creates and returns a Grade Annotation
    private func createGradeFreeTextAnnotation(gradeText: String, touchPDFPageCoordinate: CGPoint) -> PDFAnnotation {

        
        let gradeTextSize: CGSize = self.getTextSize(text: gradeText + "  ")


        let gradeFreeTextPDFAnnotation: PDFAnnotation = PDFAnnotation(bounds: CGRect(origin: touchPDFPageCoordinate, size: CGSize(width: gradeTextSize.width, height: gradeTextSize.height)), forType: PDFAnnotationSubtype.freeText, withProperties: nil)

        gradeFreeTextPDFAnnotation.fontColor = self.generalAnnotationColor
        gradeFreeTextPDFAnnotation.font = UIFont.systemFont(ofSize: self.appFontSize)
        gradeFreeTextPDFAnnotation.color = UIColor.clear
        gradeFreeTextPDFAnnotation.isReadOnly = true
        gradeFreeTextPDFAnnotation.contents = gradeText
        gradeFreeTextPDFAnnotation.userName = "GradeAnnotation"
        
        return gradeFreeTextPDFAnnotation
    }
    
    // Method calculates and returns the size of the given text in the correct font
    private func getTextSize(text: String) -> CGSize {
        let font: UIFont = UIFont.systemFont(ofSize: self.appFontSize)
        let fontAttributes: [NSAttributedStringKey: UIFont] = [NSAttributedStringKey.font: font]

        return text.size(withAttributes: fontAttributes)
    }
    
    
    
    // THe method is called when the user clicks the clear button
    // It clears all the annotations from all the selected documents
    @IBAction func clearAllAnnotations(_ sender: Any) {
        
        let alert = UIAlertController(title: "Clear Annotations", message: "Do you really want to clear all annotations?", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            print("Confirmed")
            for pageIdx in 0..<self.combinedPDFDocument.pageCount {
                
                if let page = self.combinedPDFDocument.page(at: pageIdx) {
                    
                    let annotationCount = page.annotations.count
                    
                    for index in stride(from: annotationCount-1, through: 0, by: -1) {
                        
                        page.removeAnnotation(page.annotations[index])
                    }
                }
            }
            
            for document in self.allSelectedDocuments {
                document.updateChangeCount(.done)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    // THe method updates the appearance of the top bar when the modes change
    private func updateTopBar() -> Void {

        switch self.ezGraderMode {


            case EZGraderMode.viewPDFDocuments?:
            
                UIView.animate(withDuration: 0.2) {
                    self.mainStackView.alpha = 1.0
                    self.doneStackView.alpha = 0.0
                }

            case EZGraderMode.freeHandAnnotate?,
             EZGraderMode.eraseFreeHandAnnotation?,
             EZGraderMode.textAnnotate?,
             EZGraderMode.addGrade?:
            
            UIView.animate(withDuration: 0.2) {
                self.mainStackView.alpha = 0.0
                self.doneStackView.alpha = 1.0
                
            }

            switch self.ezGraderMode {


            case EZGraderMode.freeHandAnnotate?:
                if let label = self.doneStackView.arrangedSubviews[1] as? UILabel {
                   label.text = "Add a new free-hand annotation"
                }
            case EZGraderMode.eraseFreeHandAnnotation?:
                if let label = self.doneStackView.arrangedSubviews[1] as? UILabel {
                    label.text = "Tap to erase a free-hand annotation"
                }
            case EZGraderMode.textAnnotate?:
                if let label = self.doneStackView.arrangedSubviews[1] as? UILabel {
                    label.text = "Tap to add a new text annotation"
                }
            case EZGraderMode.addGrade?:
                if let label = self.doneStackView.arrangedSubviews[1] as? UILabel {
                    label.text = "Tap to add a new grade annotation"
                }
            default:
                break
            }

            default:

                break

       }


    }
    
}

