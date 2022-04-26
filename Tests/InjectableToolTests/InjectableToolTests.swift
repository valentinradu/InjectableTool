//
//  File.swift
//
//
//  Created by Valentin Radu on 23/04/2022.
//

import Foundation
@testable import InjectableTool
import XCTest

final class InjectableToolTests: XCTestCase {
    func testBasicDefinitionFinder() async throws {
        let example = """
            import CoreData
            import Custom.Inner

            struct Empty {}

            struct Struct0: Dependency {}
            struct Struct1: AsyncFailableDependency {}
            struct Struct2: FailableDependency {}

            class Class0: Dependency {}
            class Class1: AsyncFailableDependency {}
            class Class2: FailableDependency {}

            enum Enum0: Dependency {}
            enum Enum1: AsyncFailableDependency {}
            enum Enum2: FailableDependency {}

            actor Actor0: Dependency {}
            actor Actor1: AsyncFailableDependency {}
            actor Actor2: FailableDependency {}

            extension Extension0: Dependency {}
            extension Extension1: AsyncFailableDependency {}
            extension Extension2: FailableDependency {}
        """

        let definitionsFinder = DefinitionsLookup()
        try definitionsFinder.parse(source: example)

        XCTAssertEqual(
            definitionsFinder.data.definitions,
            [
                DependencyDefinition(name: "Struct0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Struct1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Struct2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Class0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Class1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Class2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Enum0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Enum1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Enum2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Actor0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Actor1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Actor2", identifier: .failableDependency, isPublic: false),

                DependencyDefinition(name: "Extension0", identifier: .dependency, isPublic: false),
                DependencyDefinition(name: "Extension1", identifier: .asyncFailableDependency, isPublic: false),
                DependencyDefinition(name: "Extension2", identifier: .failableDependency, isPublic: false),
            ]
        )

        XCTAssertEqual(
            definitionsFinder.data.imports,
            ["CoreData", "Custom.Inner"]
        )
    }

    func testNestedDefinitionFinder() async throws {
        let example = """
            struct Nested.Struct: Dependency {}
        """

        let definitionsFinder = DefinitionsLookup()
        try definitionsFinder.parse(source: example)

        XCTAssertEqual(definitionsFinder.data.definitions,
                       [DependencyDefinition(name: "NestedStruct", identifier: .dependency, isPublic: false)])
    }

    func testBasicExtensionBuilder() async throws {
        let builder = ExtensionBuilder(
            DependencyData(definitions: [
                DependencyDefinition(name: "CustomStruct1", identifier: .dependency, isPublic: true),
                DependencyDefinition(name: "CustomStruct2", identifier: .asyncFailableDependency, isPublic: true),
                DependencyDefinition(name: "CustomStruct3", identifier: .failableDependency, isPublic: true),
            ],
            imports: ["Injectable"])
        )

        let result = try builder.build()

        let expectedResult = """

        import Injectable
        private struct CustomStruct1DependencyProviderKey: DependencyKey {
            static var defaultValue = _DependencyProvider<CustomStruct1>()
        }
        public extension SharedContainer {
            var customStruct1: ()  -> CustomStruct1 {
                get { {  self[CustomStruct1DependencyProviderKey.self].getValue(container: self) } }
                set { self[CustomStruct1DependencyProviderKey.self].replaceProvider(newValue) }
            }
        }
        private struct CustomStruct2AsyncFailableDependencyProviderKey: DependencyKey {
            static var defaultValue = _AsyncFailableDependencyProvider<CustomStruct2>()
        }
        public extension SharedContainer {
            var customStruct2: () async throws -> CustomStruct2 {
                get { { try await self[CustomStruct2AsyncFailableDependencyProviderKey.self].getValue(container: self) } }
                set { self[CustomStruct2AsyncFailableDependencyProviderKey.self].replaceProvider(newValue) }
            }
        }
        private struct CustomStruct3FailableDependencyProviderKey: DependencyKey {
            static var defaultValue = _FailableDependencyProvider<CustomStruct3>()
        }
        public extension SharedContainer {
            var customStruct3: () throws -> CustomStruct3 {
                get { { try self[CustomStruct3FailableDependencyProviderKey.self].getValue(container: self) } }
                set { self[CustomStruct3FailableDependencyProviderKey.self].replaceProvider(newValue) }
            }
        }
        """
        XCTAssertEqual(expectedResult, result)
    }
}
