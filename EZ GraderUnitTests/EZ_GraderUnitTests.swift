//
//  EZ_GraderUnitTests.swift
//  EZ GraderUnitTests
//
//  Created by Akshay Kalbhor on 11/7/18.
//  Copyright © 2018 RIT. All rights reserved.
//


import XCTest

@testable import EZ_Grader

class EZ_GraderUnitTests: XCTestCase {
    

    var pdfDocument: EZPDFDocument!
    
    override func setUp() {
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        pdfDocument = makeDefaultPDFDocument1()
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        pdfDocument = nil
    }

    func testExample() {
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let total = calcTotalGradeFor(document: pdfDocument)
        
        XCTAssertEqual(total, 45, "calcTotalGradeForDocument function has failed!")
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    func makeDefaultPDFDocument1() -> EZPDFDocument {
        return EZPDFDocument(fileURL: URL.init(string: "EMPTY")!)
    }
    
    func calcTotalGradeFor(document: EZPDFDocument) -> Int {
        return 0
    }

}
