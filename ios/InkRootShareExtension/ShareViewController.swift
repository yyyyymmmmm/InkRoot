import UIKit
import UniformTypeIdentifiers

private let appGroupIdentifier = "group.com.didichou.inkroot"
private let sharedPayloadKey = "inkroot_pending_share_payload"

final class ShareViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    processShare()
  }

  private func processShare() {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      complete()
      return
    }

    let providers = items.flatMap { $0.attachments ?? [] }
    let group = DispatchGroup()
    let lock = NSLock()
    var texts: [String] = []
    var imagePaths: [String] = []
    var filePaths: [String] = []

    for provider in providers {
      let supportsImage = provider.hasItemConformingToTypeIdentifier(UTType.image.identifier)

      if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
          if let text = item as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lock.lock()
            texts.append(text)
            lock.unlock()
          } else if let attributed = item as? NSAttributedString {
            let text = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
              lock.lock()
              texts.append(text)
              lock.unlock()
            }
          }
          group.leave()
        }
      }

      if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        group.enter()
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
          if let url = item as? URL {
            lock.lock()
            texts.append(url.absoluteString)
            lock.unlock()
          } else if let text = item as? String,
                    let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
            lock.lock()
            texts.append(url.absoluteString)
            lock.unlock()
          }
          group.leave()
        }
      }

      if supportsImage {
        group.enter()
        provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, _ in
          if let copied = self.copySharedFile(url, preferredExtension: "jpg") {
            lock.lock()
            imagePaths.append(copied.path)
            lock.unlock()
          }
          group.leave()
        }
      } else if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
        group.enter()
        provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, _ in
          if let copied = self.copySharedFile(url, preferredExtension: url?.pathExtension) {
            lock.lock()
            filePaths.append(copied.path)
            lock.unlock()
          }
          group.leave()
        }
      }
    }

    group.notify(queue: .main) {
      let payload = self.buildPayload(texts: texts, imagePaths: imagePaths, filePaths: filePaths)
      if let payload {
        self.savePayload(payload)
        self.openMainApp()
      }
      self.complete()
    }
  }

  private func buildPayload(
    texts: [String],
    imagePaths: [String],
    filePaths: [String]
  ) -> [String: Any]? {
    let cleanTexts = texts
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
    if !cleanTexts.isEmpty {
      var seen = Set<String>()
      var lines = cleanTexts.filter { seen.insert($0).inserted }
      for path in imagePaths {
        lines.append("![图片](file://\(path))")
      }
      for path in filePaths {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        lines.append("📎 \(fileName)\n路径: \(path)")
      }
      return ["type": "text", "content": lines.joined(separator: "\n")]
    }

    if imagePaths.count == 1 {
      return ["type": "image", "path": imagePaths[0]]
    }
    if imagePaths.count > 1 {
      return ["type": "images", "paths": imagePaths]
    }
    if let filePath = filePaths.first {
      return ["type": "file", "path": filePath]
    }
    return nil
  }

  private func savePayload(_ payload: [String: Any]) {
    let defaults = UserDefaults(suiteName: appGroupIdentifier)
    defaults?.set(payload, forKey: sharedPayloadKey)
    defaults?.synchronize()
  }

  private func copySharedFile(_ sourceUrl: URL?, preferredExtension: String?) -> URL? {
    guard let sourceUrl,
          let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
      return nil
    }

    let directory = container.appendingPathComponent("Shared", isDirectory: true)
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let ext = normalizedExtension(sourceUrl: sourceUrl, preferredExtension: preferredExtension)
    let fileName = "shared_\(UUID().uuidString).\(ext)"
    let destination = directory.appendingPathComponent(fileName)

    do {
      if FileManager.default.fileExists(atPath: destination.path) {
        try FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.copyItem(at: sourceUrl, to: destination)
      return destination
    } catch {
      return nil
    }
  }

  private func normalizedExtension(sourceUrl: URL, preferredExtension: String?) -> String {
    let ext = (preferredExtension?.isEmpty == false ? preferredExtension : sourceUrl.pathExtension) ?? ""
    let normalized = ext.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized.isEmpty ? "dat" : normalized
  }

  private func openMainApp() {
    guard let url = URL(string: "inkroot://share") else {
      return
    }
    extensionContext?.open(url, completionHandler: nil)
  }

  private func complete() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}
