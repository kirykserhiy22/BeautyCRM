//
//  ProductNameTests.swift
//  BeautyCRMTests
//
//  #35 — одна назва продукту.
//

import XCTest
@testable import BeautyCRM

final class ProductNameTests: XCTestCase {

    func testProductNameIsBeautyBase() {
        XCTAssertEqual(Constants.appName, "Beauty Base")
    }
}
