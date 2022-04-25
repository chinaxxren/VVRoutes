//
// Created by 赵江明 on 2022/3/3.
// Copyright (c) 2022 北京挖趣智慧有限公司. All rights reserved.
//


import UIKit

public let kVVRouteWildcardComponentsKey = "VVRouteWildcardComponents"
private let kVVRoutePatternKey = "VVRoutePattern"
private let kVVRouteURLKey = "VVRouteURL"
private let kVVRouteNamespaceKey = "VVRouteNamespace"
private let kVVRouteGlobalNamespaceKey = "VVRouteGlobalNamespace"

public typealias VVRouteHanlderBlock = ([String: Any]) -> Bool

private class Route {
    weak var parentRoutesController: VVRoutes?
    var pattern: String!
    var block: VVRouteHanlderBlock?
    var priority: Int = 0
    var patternPathComponents: [String]?
    var patternFragmentComponents: [String]?
    var matchFragmentComponents: Bool = false

    // MARK: - public methods

    public func parametersForURL(_ url: URL?, pathComponents: [String]?, fragmentComponents: [String]?) -> [String: Any]? {
        let patternNS = pattern! as NSString

        if patternPathComponents == nil {
            let fragmentIdentifier = "#"
            let range = patternNS.range(of: fragmentIdentifier)

            var pathPattern: String?
            var fragmentPattern: String?

            if range.location != NSNotFound {
                pathPattern = patternNS.substring(to: range.location)
                fragmentPattern = patternNS.substring(from: range.location + fragmentIdentifier.count)
                matchFragmentComponents = true
            } else {
                pathPattern = pattern
            }

            let filterSlashesPredicate = NSPredicate(format: "NOT SELF like '/'")
            if let pathPattern = pathPattern {
                patternPathComponents = URL(string: pathPattern)?.pathComponents.filter { (string) -> Bool in
                    filterSlashesPredicate.evaluate(with: string)
                }
            }
            if let fragmentPattern = fragmentPattern {
                patternFragmentComponents = URL(string: fragmentPattern)?.pathComponents.filter { (string) -> Bool in
                    filterSlashesPredicate.evaluate(with: string)
                }
            }
        }

        var routeParameters = [String: Any]()

        let pathParameters = _parametersForURL(url, patternComponents: patternPathComponents, components: pathComponents)
        if pathParameters == nil {
            return nil
        }

        if matchFragmentComponents {
            let fragmentParameters = _parametersForURL(url, patternComponents: patternFragmentComponents, components: fragmentComponents)
            if fragmentParameters == nil {
                return nil
            }
            if let fragmentParameters = fragmentParameters {
                routeParameters.mergeOther(fragmentParameters)
            }
        }

        if let pathParameters = pathParameters {
            routeParameters.mergeOther(pathParameters)
        }

        return routeParameters
    }

    // MARK: - private methods

    private func _parametersForURL(_: URL?, patternComponents: [String]?, components: [String]?) -> [String: Any]? {
        var routeParameters: [String: Any]?

        let componentCountEqual = patternComponents?.count == components?.count
        let patternContainsWildcard = patternComponents?.contains("*") ?? false

        guard let patternComponents = patternComponents else {
            return nil
        }

        guard var components = components else {
            return nil
        }

        if componentCountEqual || patternContainsWildcard {
            var componentIndex: Int = 0
            var variables = [String: Any]()
            var isMatch = true

            for patternComponent in patternComponents {
                var URLComponent: String?
                if componentIndex < components.count {
                    URLComponent = components[componentIndex]
                } else if patternComponent == "*" { // match /foo by /foo/*
                    URLComponent = components.last
                }
                let patternComponentNS: NSString = patternComponent as NSString
                if patternComponent.hasPrefix(":") {
                    let variableName = patternComponentNS.substring(from: 1)
                    let variableValue = URLComponent ?? ""

                    let urlDecodedVariableValue = variableValue.toURLDecodedString()
                    if let urlDecodedVariableValue = urlDecodedVariableValue, variableName.count > 0, urlDecodedVariableValue.count > 0 {
                        variables[variableName] = urlDecodedVariableValue
                    } else {
                        var newComponents = [String]() + components
                        newComponents.append("")
                        components = newComponents
                    }
                } else if patternComponent == "*" {
                    variables[kVVRouteWildcardComponentsKey] = components[componentIndex..<components.count - componentIndex]
                    isMatch = true
                    break
                } else if patternComponent != URLComponent {
                    isMatch = false
                    break
                }
                componentIndex += 1
            }

            if isMatch {
                routeParameters = variables
            }
        }

        return routeParameters
    }
}

extension Route: CustomStringConvertible {
    var description: String {
        return "<VVRoute> - \(pattern ?? "") - (priority: \(priority))"
    }
}

open class VVRoutes {
    private static var routeControllersMap = [String?: VVRoutes?]()
    private var routes = [Route]()
    private var namespaceKey: String = kVVRouteGlobalNamespaceKey

    public static var verboseLoggingEnabled: Bool = false
    public static var shouldDecodePlusSymbols: Bool = true
    open var shouldFallbackToGlobalRoutes = false
    open var unmatchedURLHandler: ((VVRoutes, URL, [String: Any]?) -> Void)?

    // MARK: - public methods

    public static func routesForScheme(_ scheme: String) -> VVRoutes? {
        var routesController: VVRoutes?

        if routeControllersMap[scheme] == nil {
            routesController = VVRoutes()
            routesController?.namespaceKey = scheme
            routeControllersMap[scheme] = routesController
        }

        routesController = routeControllersMap[scheme] as? VVRoutes

        return routesController
    }

    // MARK: - register && unregister

    public func addRoute(pattern: String, priority: Int = 0, handler: @escaping VVRouteHanlderBlock) {
        let optionalRoutePatterns = _optionalRoutesForPattern(pattern)

        if let optionalRoutePatterns = optionalRoutePatterns, optionalRoutePatterns.count > 0 {
            for route in optionalRoutePatterns {
                VVRoutesUtil.printLog("Automatically created optional route: \(route)")
                registerRoute(pattern: route, priority: priority, handler: handler)
            }
            return
        }

        registerRoute(pattern: pattern, priority: priority, handler: handler)
    }

    public func addRoutes(patterns: [String], handler: @escaping VVRouteHanlderBlock) {
        for pattern in patterns {
            addRoute(pattern: pattern, handler: handler)
        }
    }

    public func removeRoute(pattern: String) {
        var routePattern = pattern

        if !routePattern.hasPrefix("/") {
            routePattern = "/\(routePattern)"
        }

        var routeIndex = NSNotFound
        var index = 0

        for route in routes {
            if route.pattern == routePattern {
                routeIndex = index
                break
            }
            index += 1
        }

        if routeIndex != NSNotFound {
            routes.remove(at: routeIndex)
        }
    }

    public func removeAllRoutes() {
        routes.removeAll()
    }

    public func setHandlerBlock(_ hanlderBlock: @escaping VVRouteHanlderBlock, forKeyedSubscript routePatten: String) {
        addRoute(pattern: routePatten, handler: hanlderBlock)
    }

    public static func unregisterRouteScheme(_ scheme: String) {
        routeControllersMap.removeValue(forKey: scheme)
    }

    public static func unregisterAllRouteSchemes() {
        routeControllersMap.removeAll()
    }

    public static func globalRoutes() -> VVRoutes? {
        return routesForScheme(kVVRouteGlobalNamespaceKey)
    }

    // MARK: - judge

    public static func canRouteURL(_ url: URL) -> Bool {
        if let result = routesControllerForURL(url: url)?.canRouteURL(url) {
            return result
        }
        return false
    }

    public func canRouteURL(_ url: URL) -> Bool {
        return routeURL(url, parameters: nil, executeRouteBlock: false)
    }

    public func routeURL(_ url: URL, parameters: [String: Any]? = nil) -> Bool {
        return routeURL(url, parameters: parameters, executeRouteBlock: true)
    }

    // MARK: - route

    @discardableResult
    public static func routeURL(_ url: URL, parameters: [String: Any]? = nil) -> Bool {
        if let route = routesControllerForURL(url: url) {
            return route.routeURL(url, parameters: parameters)
        } else {
            return false
        }
    }

    @discardableResult
    public static func openURL(_ string: String, parameters: [String: Any]? = nil) -> Bool {
        guard let url = URL(string: string) else {
            return false
        }

        if let route = routesControllerForURL(url: url) {
            return route.routeURL(url, parameters: parameters)
        } else {
            return false
        }
    }

    // MARK: - private methods

    private func _isGlobalRoutesController() -> Bool {
        return namespaceKey == kVVRouteGlobalNamespaceKey
    }

    private func registerRoute(pattern: String, priority: Int, handler: @escaping VVRouteHanlderBlock) {
        let route = Route()
        route.pattern = pattern
        route.priority = priority
        route.block = handler
        route.parentRoutesController = self

        if route.block == nil {
            route.block = { _ in
                true
            }
        }

        if priority == 0 || routes.count == 0 {
            routes.append(route)
        } else {
            let existingRoutes = routes
            var index: Int = 0
            var addedRoute = false

            for existingRoute in existingRoutes {
                if existingRoute.priority < priority {
                    routes.insert(route, at: index)
                    addedRoute = true
                    break
                }
                index += 1
            }

            if !addedRoute {
                routes.append(route)
            }
        }
    }

    private func routeURL(_ url: URL?, parameters: [String: Any]? = nil, executeRouteBlock: Bool) -> Bool {
        if url == nil {
            return false
        }

        VVRoutesUtil.printLog("Trying to route URL\(String(describing: url))")

        var didRoute: Bool = false
        let queryParameters = url?.query?.toURLParameterDict()

        VVRoutesUtil.printLog("Parsed query parameters:\(String(describing: queryParameters))")

        let fragmentParameters = url?.fragment?.toURLParameterDict()
        VVRoutesUtil.printLog("Parsed fragment parameters:\(String(describing: fragmentParameters))")

        let fragmentQueryParameters = url?.fragmentQuery()?.toURLParameterDict()
        VVRoutesUtil.printLog("Parsed fragment query parameters:\(String(describing: fragmentQueryParameters))")

        let filterSlashesPredicate = NSPredicate(format: "NOT SELF like '/'")
        let components = url?.pathComponents ?? [String]()
        var pathComponents = components.filter { (string) -> Bool in
            filterSlashesPredicate.evaluate(with: string)
        }

        let fragmentPathComponents = url?.fragmentPathComponents() ?? [String]()
        let fragmentComponents = fragmentPathComponents.filter { (string) -> Bool in
            filterSlashesPredicate.evaluate(with: string)
        }

        if url?.host?.rangeOfCharacter(from: CharacterSet(charactersIn: ".")) == nil, url?.host != "localhost" {
            if let host = url?.host {
                pathComponents = [host] + pathComponents
            }
        }

        VVRoutesUtil.printLog("URL path components:\(String(describing: pathComponents))")
        VVRoutesUtil.printLog("URL fragment components:\(String(describing: fragmentComponents))")

        for route in routes {
            let matchParameters = route.parametersForURL(url, pathComponents: pathComponents, fragmentComponents: fragmentComponents)
            if matchParameters != nil {
                VVRoutesUtil.printLog("Successfully matched:\(String(describing: route))")
                if !executeRouteBlock {
                    return true
                }

                var finalParameters = [String: Any]()
                if let queryParameters = queryParameters {
                    finalParameters.mergeOther(queryParameters)
                }

                if route.matchFragmentComponents {
                    if let fragmentQueryParameters = fragmentQueryParameters {
                        finalParameters.mergeOther(fragmentQueryParameters)
                    }
                } else {
                    if let fragmentParameters = fragmentParameters {
                        finalParameters.mergeOther(fragmentParameters)
                    }
                }

                if let matchParameters = matchParameters {
                    finalParameters.mergeOther(matchParameters)
                }

                if let parameters = parameters {
                    finalParameters.mergeOther(parameters)
                }

                finalParameters[kVVRoutePatternKey] = route.pattern
                finalParameters[kVVRouteURLKey] = url

                if let strongParentRoutesController = route.parentRoutesController {
                    finalParameters[kVVRouteNamespaceKey] = strongParentRoutesController.namespaceKey
                }
                VVRoutesUtil.printLog("Final parameters are:\(String(describing: finalParameters))")
                if let result = route.block?(finalParameters) {
                    didRoute = result
                }
                if didRoute {
                    break
                }
            }
        }
        if !didRoute {
            VVRoutesUtil.printLog("Could not find a matching route, returning NO")
        }

        if !didRoute, shouldFallbackToGlobalRoutes, !_isGlobalRoutesController() {
            VVRoutesUtil.printLog("Falling back to global routes...")
            if let result = VVRoutes.globalRoutes()?.routeURL(url, parameters: parameters, executeRouteBlock: executeRouteBlock) {
                didRoute = result
            }
        }

        if let unmatchedURLHandler = unmatchedURLHandler, let url = url, !didRoute, executeRouteBlock {
            unmatchedURLHandler(self, url, parameters)
        }

        return didRoute
    }

    private static func routesControllerForURL(url: URL?) -> VVRoutes? {
        if url == nil {
            return nil
        }

        return routeControllersMap[url?.scheme] ?? globalRoutes()
    }

    // MARK: - generating optional routes

    private func _optionalRoutesForPattern(_ routePattern: String) -> [String]? {
        /* this method exists to take a route pattern that is known to contain optional params, such as:

         /path/:thing/(/a)(/b)(/c)

         and create the following paths:

         /path/:thing/a/b/c
         /path/:thing/a/b
         /path/:thing/a/c
         /path/:thing/b/a
         /path/:thing/a
         /path/:thing/b
         /path/:thing/c
         /path/:thing/
         */
        if routePattern.range(of: "(") == nil {
            return nil
        }

        var baseRoute: String?
        let components = _optionalComponentsForPattern(routePattern, outBaseRoute: &baseRoute)
        let routes = _routesForOptionalComponents(components, baseRoute: baseRoute)

        return routes
    }

    private func _optionalComponentsForPattern(_ routePattern: String, outBaseRoute: inout String?) -> [String]? {
        if routePattern.count <= 0 {
            return nil
        }
        var optionalComponents = [String]()

        let scanner = Scanner(string: routePattern)
        var nonOptionalRouteSubpath: NSString?

        var parsedBaseRoute = false
        var parseError = false

        while scanner.scanUpTo("(", into: &nonOptionalRouteSubpath) {
            if scanner.isAtEnd {
                break
            }
            if let nonOptionalRouteSubpath = nonOptionalRouteSubpath, nonOptionalRouteSubpath.length > 0, !parsedBaseRoute {
                // the first 'non optional susbpath' is always the base route
                outBaseRoute = nonOptionalRouteSubpath as String
                parsedBaseRoute = true
            }

            scanner.scanLocation = scanner.scanLocation + 1

            var component: NSString?
            if !scanner.scanUpTo(")", into: &component) {
                parseError = true
                break
            }
            if let component = component {
                optionalComponents.append(component as String)
            }
        }
        if parseError {
            VVRoutesUtil.printLog("[JLRoutes]: Parse error, unsupported route: \(routePattern)")
            return nil
        }

        return optionalComponents
    }

    private func _routesForOptionalComponents(_ optionalComponents: [String]?, baseRoute: String?) -> [String]? {
        guard let baseRoute = baseRoute, let optionalComponents = optionalComponents, optionalComponents.count != 0, baseRoute.count != 0 else {
            return nil
        }

        var routes = [String]()
        let combinations = optionalComponents.allOrderedCombinations()
        for components in combinations {
            routes.append(baseRoute + components)
        }
        routes.sort { (s1, s2) -> Bool in
            s1.count > s2.count
        }

        return routes
    }
}

extension VVRoutes: CustomStringConvertible {
    public var description: String {
        return routes.description
    }

    public static func allRoutes() -> String {
        var descriptionString = "\n"

        for (_, routesController) in routeControllersMap {
            if let routesController = routesController {
                descriptionString += "\"\(routesController.namespaceKey)\":\n\(routesController.routes)\n"
            }
        }

        return descriptionString
    }
}
