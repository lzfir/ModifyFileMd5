//
//  main.swift
//  ModifyFileMd5
//
//  Created by FIRF on 2024/10/31.
//

import Foundation
import CryptoKit

// MARK: 输出颜色
enum ColorOutputEnum: String {
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    /// 重置颜色(结尾)
    static let reset = "\u{001B}[0m"
}

extension String {
    func output(_ color: ColorOutputEnum) -> String {
        return "\(color.rawValue)\(self)\(ColorOutputEnum.reset)"
    }
}

func printColor(_ colorString: String, _ description: String) {
    print(colorString.output(.red), description)
}


// MARK: MD5

func md5File(url: URL) -> String? {
    do {
        var hasher = Insecure.MD5()
        let bufferSize = 1024 * 1024 * 32 // 32MB

        let fileHandler = try FileHandle(forReadingFrom: url)
        fileHandler.seekToEndOfFile()
        let size = fileHandler.offsetInFile
        try fileHandler.seek(toOffset: 0)

        while fileHandler.offsetInFile < size {
            autoreleasepool {
                let data = fileHandler.readData(ofLength: bufferSize)
                hasher.update(data: data)
            }
        }

        let digest = hasher.finalize()
        return digest.map { String(format: "%02hhx", $0) }.joined()
    } catch {
        print("[-] error reading file: \(error)")
        return nil
    }
}

// MARK: 打印帮助信息
func printUsage() {
    print("Welcome to Modify File Md5!".output(.red))
    print("Usage: CommandLineTool <option> [arguments...]")
    print("Options:")
    print("  -h, --help               Show this help message.")
    print("  -v, --version  Specify a value to update the key with.")
    print("  -d, --directory <path>   Specify the path to the directory.")
    print("  -md5 <path> Specify the path to the file.")
}


/// 递归修改文件夹image md5
/// - Parameter directoryPath: 文件夹路径
func modifyImages(at directoryPath: String) {
    // 使用 FileManager 检查是否为目录并遍历文件
    let fileManager = FileManager.default
    
    guard let items = try? fileManager.contentsOfDirectory(atPath: directoryPath) else {
        printColor("Error: >>>", "Failed to read directory at \(directoryPath)")
        return
    }
    
    for item in items {
        let fullPath = "\(directoryPath)/\(item)"
        var isDirectory: ObjCBool = false
        // 检查是否是目录
        if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory), isDirectory.boolValue {
            // 如果是目录则递归
            modifyImages(at: fullPath)
        } else {
            modifyImage(at: fullPath)
        }
    }
}

/// 修改单个文件md5
func modifyImage(at filePath: String) {
    
    if filePath.hasSuffix(".png") || filePath.hasSuffix(".PNG") || filePath.hasSuffix(".jpg") || filePath.hasSuffix("bmp") {

        do {
            let fileURL = URL(fileURLWithPath: filePath)
            
            let md5String1 = md5File(url: fileURL)
            print("\(fileURL.lastPathComponent) md51 = \(md5String1 ?? "")")
            
            // !!!: 生成 UUID 并将其追加到文件末尾
            let uuid = UUID().uuidString
            let uuidData = (uuid + "\n").data(using: .utf8)!
      
            if let fileHandle = FileHandle(forWritingAtPath: filePath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(uuidData)
                fileHandle.closeFile()
                 print("[🍺🍺🍺] >>> ", "add uuid to \(fileURL.lastPathComponent) success.")
                // print("[🍺🍺🍺]Added UUID to \(fullPath)")
            } else {
                printColor("Error: >>>", "Cannot open file  at \(fileURL) for writing.")
            }
            // let md5String1 = md5File(url: fileURL)
            print("\(fileURL.lastPathComponent) md51 = \(md5String1 ?? "")")

        } catch {
            printColor("Error: >>>", "Failed to write to file at \(filePath): \(error)")
        }
    }
}

// MARK: main
private func main() {

    // 限制输入参数
    guard CommandLine.argc >= 2, CommandLine.argc <= 3 else {
        printUsage()
        return
    }
    let arguments = CommandLine.arguments
    
    var directoryPath: String?
    var md5FilePath: String?
 
    // 循环遍历奇数下标
    for index in stride(from: 1, to: arguments.count, by: 2) {
        let arg = arguments[index]
        switch arg {
        case "-h", "--help":
            printUsage()
            return
        case "-v", "--version":
            print("Magic image. version 1.0")
            return
        case "-d", "--directory":
            if index + 1 < arguments.count {
                directoryPath = arguments[index + 1]
            } else {
                printColor("Error: >>>","No directory provided after -d option.")
                return
            }
        case "-md5":
            if index + 1 < arguments.count {
                md5FilePath = arguments[index + 1]
            } else {
                printColor("Error: >>>","No file provided after -md5 option.")
                return
            }
        default:
            printColor("Error: >>>", "Unknown option \(arg).")
            return
        }
    }

    if let directoryPath = directoryPath {
        print("directoryPath = \(directoryPath)")
        modifyImages(at: directoryPath)
    }
    
    if let md5FilePath = md5FilePath {
        guard let md5String = md5File(url: URL(fileURLWithPath: md5FilePath)) else {
            printColor("Error: >>>", "something wrong!")
            return
        }
        print(md5String)
    }
}

// MARK: execute main
main()






