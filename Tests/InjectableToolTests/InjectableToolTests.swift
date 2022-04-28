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

            import Foundation
        
            final class Class0: Dependency {}
            final class Class1: AsyncFailableDependency {}
            final class Class2: FailableDependency {}

            enum Enum0: Dependency {}
            enum Enum1: AsyncFailableDependency {}
            enum Enum2: FailableDependency {}

            public actor Actor0: Dependency {}
            public actor Actor1: AsyncFailableDependency {}
            public actor Actor2: FailableDependency {}

            extension Extension0: Dependency {}
            extension Extension1: AsyncFailableDependency {}
            extension Extension2: FailableDependency {}
        """

        let definitionsFinder = DefinitionsLookup()
        try definitionsFinder.parse(source: example)

        XCTAssertEqual(
            definitionsFinder.data.definitions,
            [
                DependencyDefinition(name: "Struct0", identifier: .dependency),
                DependencyDefinition(name: "Struct1", identifier: .asyncFailableDependency),
                DependencyDefinition(name: "Struct2", identifier: .failableDependency),

                DependencyDefinition(name: "Class0", identifier: .dependency),
                DependencyDefinition(name: "Class1", identifier: .asyncFailableDependency),
                DependencyDefinition(name: "Class2", identifier: .failableDependency),

                DependencyDefinition(name: "Enum0", identifier: .dependency),
                DependencyDefinition(name: "Enum1", identifier: .asyncFailableDependency),
                DependencyDefinition(name: "Enum2", identifier: .failableDependency),

                DependencyDefinition(name: "Actor0", identifier: .dependency),
                DependencyDefinition(name: "Actor1", identifier: .asyncFailableDependency),
                DependencyDefinition(name: "Actor2", identifier: .failableDependency),

                DependencyDefinition(name: "Extension0", identifier: .dependency),
                DependencyDefinition(name: "Extension1", identifier: .asyncFailableDependency),
                DependencyDefinition(name: "Extension2", identifier: .failableDependency),
            ]
        )

        XCTAssertEqual(
            definitionsFinder.data.imports,
            ["CoreData", "Custom.Inner", "Foundation"]
        )
    }

    func testNestedDefinitionFinder() async throws {
        let example = """
            struct Nested.Struct: Dependency {}
        """

        let definitionsFinder = DefinitionsLookup()
        try definitionsFinder.parse(source: example)

        XCTAssertEqual(definitionsFinder.data.definitions,
                       [DependencyDefinition(name: "NestedStruct", identifier: .dependency)])
    }

    func testBasicExtensionBuilder() async throws {
        let builder = ExtensionBuilder(
            DependencyData(definitions: [
                DependencyDefinition(name: "CustomStruct1", identifier: .dependency),
                DependencyDefinition(name: "CustomStruct2", identifier: .asyncFailableDependency),
                DependencyDefinition(name: "CustomStruct3", identifier: .failableDependency),
            ],
            imports: ["Injectable", "AudioUnit"])
        )

        let result = try builder.build()

        let expectedResult = """

        import Injectable
        import AudioUnit
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
