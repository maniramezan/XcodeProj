import Foundation
import XCTest
import PathKit
@testable import XcodeProj

class ReferenceGeneratorTests: XCTestCase {

    func test_projectReferencingRemoteXcodeprojBundle_convertsReferencesToPermanent() throws {
        let project = PBXProj(rootObject: nil, objectVersion: 0, archiveVersion: 0, classes: [:], objects: [])
        let pbxProject = project.makeProject()
        let remoteProjectFileReference = project.makeFileReference()
        let containerItemProxy = project.makeContainerItemProxy(fileReference: remoteProjectFileReference)
        let productReferenceProxy = project.makeReferenceProxy(containerItemProxy: containerItemProxy)
        let productsGroup = project.makeProductsGroup(children: [productReferenceProxy])

        pbxProject.projectReferences.append([ "ProductGroup" : productsGroup.reference ])

        let referenceGenerator = ReferenceGenerator(outputSettings: PBXOutputSettings())
        try referenceGenerator.generateReferences(proj: project)

        XCTAssert(!productsGroup.reference.temporary)
        XCTAssert(!containerItemProxy.reference.temporary)
        XCTAssert(!productReferenceProxy.reference.temporary)
        XCTAssert(!remoteProjectFileReference.reference.temporary)
    }
}

private extension PBXProj {
    func makeProject() -> PBXProject {
        let mainGroup = PBXGroup(children: [],
                                 sourceTree: .group,
                                 name: "Main")

        let project = PBXProject(name: "test",
                                 buildConfigurationList: XCConfigurationList.fixture(),
                                 compatibilityVersion: Xcode.Default.compatibilityVersion,
                                 mainGroup: mainGroup)

        self.add(object: mainGroup)
        self.add(object: project)
        self.rootObject = project

        return project
    }

    func makeFileReference() -> PBXFileReference {
        return try! self.rootObject!.mainGroup.addFile(at: Path("../Remote.xcodeproj"), sourceRoot: Path("/"), validatePresence: false)
    }

    func makeContainerItemProxy(fileReference: PBXFileReference) -> PBXContainerItemProxy {
        let containerItemProxy = PBXContainerItemProxy(containerPortal: .fileReference(fileReference),
                                                       remoteGlobalID: .string("remoteTargetGlobalIDString"),
                                                       proxyType: .reference,
                                                       remoteInfo: "RemoteTarget")

        self.add(object: containerItemProxy)

        return containerItemProxy
    }

    func makeReferenceProxy(containerItemProxy: PBXContainerItemProxy) -> PBXReferenceProxy {
        let productReferenceProxy = PBXReferenceProxy(fileType: "wrapper.pb-project",
                                                      path: "Remote.framework",
                                                      remote: containerItemProxy,
                                                      sourceTree: .buildProductsDir)
        self.add(object: productReferenceProxy)
        return productReferenceProxy
    }

    func makeProductsGroup(children: [PBXFileElement]) -> PBXGroup {
        let productsGroup = PBXGroup(children: children,
                                     sourceTree: .group,
                                     name: "Products")
        self.add(object: productsGroup)
        return productsGroup
    }
}
