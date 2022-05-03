//
//  File.swift
//
//
//  Created by Valentin Radu on 23/04/2022.
//

import Foundation
@testable import ToledoTool
import XCTest

final class ToledoToolTests: XCTestCase {
    func testBasicDefinitionFinder() async throws {
        let example = """
            import CoreData
            import Custom.Inner

            struct Empty {}

            struct Struct0: Dependency {}
            struct Struct1: AsyncThrowingDependency {}
            struct Struct2: ThrowingDependency {}

            import Foundation

            final class Class0: Dependency {}
            final class Class1: AsyncThrowingDependency {}
            final class Class2: ThrowingDependency {}

            enum Enum0: Dependency {}
            enum Enum1: AsyncThrowingDependency {}
            enum Enum2: ThrowingDependency {}

            public actor Actor0: Dependency {}
            public actor Actor1: AsyncThrowingDependency {}
            public actor Actor2: ThrowingDependency {}

            extension Extension0: Dependency {}
            extension Extension1: AsyncThrowingDependency {}
            extension Extension2: ThrowingDependency {}
        """

        let definitionsFinder = DefinitionsLookup()
        try definitionsFinder.parse(source: example)

        XCTAssertEqual(
            definitionsFinder.data.definitions,
            [
                DependencyDefinition(name: "Struct0", identifier: .dependency),
                DependencyDefinition(name: "Struct1", identifier: .asyncThrowingDependency),
                DependencyDefinition(name: "Struct2", identifier: .throwingDependency),

                DependencyDefinition(name: "Class0", identifier: .dependency),
                DependencyDefinition(name: "Class1", identifier: .asyncThrowingDependency),
                DependencyDefinition(name: "Class2", identifier: .throwingDependency),

                DependencyDefinition(name: "Enum0", identifier: .dependency),
                DependencyDefinition(name: "Enum1", identifier: .asyncThrowingDependency),
                DependencyDefinition(name: "Enum2", identifier: .throwingDependency),

                DependencyDefinition(name: "Actor0", identifier: .dependency),
                DependencyDefinition(name: "Actor1", identifier: .asyncThrowingDependency),
                DependencyDefinition(name: "Actor2", identifier: .throwingDependency),

                DependencyDefinition(name: "Extension0", identifier: .dependency),
                DependencyDefinition(name: "Extension1", identifier: .asyncThrowingDependency),
                DependencyDefinition(name: "Extension2", identifier: .throwingDependency),
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
                DependencyDefinition(name: "CustomStruct2", identifier: .throwingDependency),
                DependencyDefinition(name: "CustomStruct3", identifier: .asyncThrowingDependency),
            ],
            imports: ["Toledo", "AudioUnit"])
        )

        let result = try builder.build()

        let expectedResult = """

        import Toledo
        import AudioUnit
        public struct CustomStruct1DependencyProviderKey: DependencyKey {
            public static let defaultValue = _DependencyProvider<CustomStruct1>()
        }
        public extension SharedContainer {
            func customStruct1()  -> CustomStruct1.ResolvedTo {
                 self[CustomStruct1DependencyProviderKey.self].getValue(container: self)
            }
        }
        public struct CustomStruct2ThrowingDependencyProviderKey: DependencyKey {
            public static let defaultValue = _ThrowingDependencyProvider<CustomStruct2>()
        }
        public extension SharedContainer {
            func customStruct2() throws -> CustomStruct2.ResolvedTo {
                try self[CustomStruct2ThrowingDependencyProviderKey.self].getValue(container: self)
            }
        }
        public struct CustomStruct3AsyncThrowingDependencyProviderKey: DependencyKey {
            public static let defaultValue = _AsyncThrowingDependencyProvider<CustomStruct3>()
        }
        public extension SharedContainer {
            func customStruct3() async throws -> CustomStruct3.ResolvedTo {
                try await self[CustomStruct3AsyncThrowingDependencyProviderKey.self].getValue(container: self)
            }
        }
        """
        XCTAssertEqual(expectedResult, result)
    }
}
