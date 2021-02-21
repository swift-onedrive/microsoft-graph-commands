import Foundation
import ArgumentParser
import OneDrive
import Core
import NIO
import AsyncHTTPClient

let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
let client = HTTPClient(eventLoopGroupProvider: .shared(elg),
                        configuration: .init(ignoreUncleanSSLShutdown: true))
defer {
    try? client.syncShutdown()
}

struct Drive: ParsableCommand {
    // swift run Commands --version
    static var configuration = CommandConfiguration(
        // Optional abstracts and discussions are used for help output.
        abstract: "A onedrive Command",
        // Commands can define a version for automatic '--version' support.
        version: "1.0.0"
    )
    
    @Argument(help: "drive folder")
    var folder: String = "temp"
    
    @Argument(help: "file path")
    var filePath: String
    
    @Option(help: "File name")
    var name: String?
    
    @Flag(help: "Absolute path")
    var absolutePath = false
    
    // swift run Commands temp ./README.md --name README.md
    mutating func run() throws {
        let envUrl = URL(fileURLWithPath: "./.env")
        let envString = try String(contentsOf: envUrl, encoding: .utf8)
        let envArr = envString.split(separator: "\n")

        guard let i = envArr.firstIndex(where: { $0.hasPrefix("TENANT_ID") }),
              let tenantId = envArr[i].split(separator: "=").last else {
            return
        }
        guard let j = envArr.firstIndex(where: { $0.hasPrefix("CLIENT_ID") }),
              let clientId = envArr[j].split(separator: "=").last else {
            return
        }
        guard let k = envArr.firstIndex(where: { $0.hasPrefix("SECRET") }),
              let secret = envArr[k].split(separator: "=").last else {
            return
        }
        
        let fileUrl = URL(fileURLWithPath: filePath)
        print("\(fileUrl) tenantId: \(tenantId) clientId:\(clientId)")
        
        let credentialsConfiguration = MsGraphCredentialsConfiguration.init(credentials:.init(tenantId: String(tenantId),
                                                                                               clientId: String(clientId),
                                                                                               secret: String(secret)))
        var objectID = ""
        if let l = envArr.firstIndex(where: { $0.hasPrefix("OBJECT_ID") }),
           let objectId = envArr[l].split(separator: "=").last {
            objectID = String(objectId)
        }
        let onedrive = try OneDriveClient.init(credentials: credentialsConfiguration, driveConfig: .init(objectID: objectID), httpClient: client, eventLoop: elg.next())
        
        
        let large = onedrive.driveItem
            .createLargeFileUploadSession(folder: folder, fileUrl: fileUrl, name: name ?? fileUrl.lastPathComponent)
            .flatMap { (response) -> EventLoopFuture<FileDriveItemModel> in
                return onedrive.driveItem.startLargeFileChunk(fileUrl: fileUrl, uploadUrlString: response.uploadUrl)
            }
        let largeModel = try large.wait()
        print(largeModel)
        
    }
}

Drive.main()
