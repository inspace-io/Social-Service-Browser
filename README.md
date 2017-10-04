[![](http://inspace.io/github-cover.jpg)](http://inspace.io)

# Introduction

**SocialServiceBrowser** was written by **[Michał Zaborowski](https://github.com/m1entus)** for **[inspace.io](http://inspace.io)**

# SocialServiceBrowser

`SocialServiceBrowser` provides a simple way to browse, preview and import files from external services like Dropbox, Amazon Drive, Google Drive etc. It is written in `Swift` for iOS.
Currently it has implementation only for Dropbox and is using newest Dropbox API v2 and [SwiftyDropbox](https://github.com/dropbox/SwiftyDropbox).

[![](https://raw.github.com/inspace-io/Social-Service-Browser/master/Screens/1.gif)](https://raw.github.com/inspace-io/Social-Service-Browser/master/Screens/1.gif)
[![](https://raw.github.com/inspace-io/Social-Service-Browser/master/Screens/2.gif)](https://raw.github.com/inspace-io/Social-Service-Browser/master/Screens/2.gif)

# Simple Usage

```swift
let configuration = SocialServiceBrowserConfigurator(client: SocialServiceBrowserDropboxClient(), selectionMode: .select)
let viewController = SocialServiceBrowserViewController(configuration: configuration, uiConfiguration: configuration)
viewController.delegate = self
present(UINavigationController(rootViewController: viewController), animated: true, completion: nil)
```

```swift
extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self.presentedViewController!
    }
}

extension ViewController: SocialServiceBrowserViewControllerDelegate {
    fileprivate func showDocumentBrowser(for url: URL) {
        let documentBrowser = UIDocumentInteractionController(url: url)
        documentBrowser.delegate = self
        documentBrowser.presentPreview(animated: true)
    }

    func socialServiceBrowser(_ socialServiceBrowser: SocialServiceBrowserViewController, didSelect node: SocialServiceBrowerNode) {
      socialServiceBrowser.importNode(node) { [weak self] node, error in
          if let node = node {
              self?.showDocumentBrowser(for: node.fileURL)
          }
      }
    }
}
```

# Custom Cells and layout

SocialServiceBrowserViewController is configured with two objects which needs implement `SocialServiceBrowserViewControllerConfigurable` and `SocialServiceBrowserViewControllerUIConfigurable`.

```swift
public init(configuration: SocialServiceBrowserViewControllerConfigurable, uiConfiguration: SocialServiceBrowserViewControllerUIConfigurable) {
```

If you want to change navigation bar button styles or implement custom `UICollectionViewCells` you should implement `SocialServiceBrowserViewControllerUIConfigurable` in your class which look like this:

```swift
public enum SocialServiceBrowserDisplayMode {
    case list
    case grid
}

public protocol SocialServiceBrowserViewControllerUIConfigurable {
    var displayMode: SocialServiceBrowserDisplayMode { get }

    var backBarButtonItem: UIBarButtonItem { get }
    var closeBarButtonItem: UIBarButtonItem { get }
    var importBarButtonItem: UIBarButtonItem { get }

    func registerCells(for collectionView: UICollectionView)
    func reusableIdentifierForCell(`in` displayMode: SocialServiceBrowserDisplayMode) -> String
    func reusableIdentifierForHeader(`in` displayMode: SocialServiceBrowserDisplayMode) -> String
}
```

By default browser support two layouts, grid layout and list layout, you can set it by returning `displayMode` property from object which implements `SocialServiceBrowserViewControllerUIConfigurable`.

# Custom Browser Client

To be able to implement custom browser client all you need to do is implement methods from `SocialServiceBrowserClient` protocol:

```swift
public protocol SocialServiceBrowserClient {
    var serviceName: String { get }
    var filter: SocialServiceBrowserFilterType { get }

    func requestRootNode(with completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?

    func requestChildren(`for` node: SocialServiceBrowerNode, withCompletion completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?

    func requestThumbnail(`for` node: SocialServiceBrowerNode, withCompletion: @escaping (SocialServiceBrowserResult<UIImage, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?

    func requestData(`for` node: SocialServiceBrowerNode, withCompletion: @escaping (SocialServiceBrowserResult<URL, Error>) -> Void) -> SocialServiceBrowserOperationPerformable?
}
```

as an example you can look on `SocialServiceBrowserDropboxClient` class.

```swift
func requestRootNode(with completion: @escaping (SocialServiceBrowserResult<SocialServiceBrowerNodeListResponse, Error>) -> Void) -> SocialServiceBrowserOperationPerformable? {
        return client?.files.listFolder(path: "").response(completionHandler: { [weak self] response, error in
            if let error = error {
                completion(SocialServiceBrowserResult.failure(NSError(domain: "SocialServiceBrowserDropboxClientDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: error.description] as [String: Any])))
            } else if let response = response {
                response.filter = self?.filter
                completion(SocialServiceBrowserResult.success(response))
            } else {
                fatalError()
            }
        }).request
    }
```

## SocialServiceBrowser

Add the following to your `Podfile` and run `$ pod install`.

``` ruby
pod 'SocialServiceBrowser'
```

If you don't have CocoaPods installed, you can learn how to do so [here](http://cocoapods.org).

## Contact

[inspace.io](http://inspace.io)

[Twitter](https://twitter.com/inspace_io)

# License
```
Copyright © 2017 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this library except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.```
