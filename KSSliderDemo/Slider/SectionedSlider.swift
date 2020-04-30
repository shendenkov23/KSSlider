//
//  SectionedSlider.swift
//  KSSlider
//
//  Created by shendenkov23 on 11.01.18.
//  Copyright © 2020 shendenkov23. All rights reserved.
//

import UIKit

// MARK: -

public protocol SectionedSliderDelegate: class {
  func doubleTapped(on section: Int)
  func sectionChanged(slider: SectionedSlider, selected: Int)
}

// MARK: -

public class SectionedSlider: UIView {
  var bodyPath: UIBezierPath?
  var sliderPath: UIBezierPath?
  var sliderBodyPath: UIBezierPath?
  
  var viewBackgroundColor: UIColor?
  var sliderBackgroundColor: UIColor?
  var sliderColor: UIColor?
  var selectedSectionOnPreviousTouch: Int?
  
  fileprivate(set) var sections: Int = 20
  fileprivate var halfSections: Bool
  
  private var factor: CGFloat = 0.0 {
    willSet {
      if factor != newValue {
        let currentSection = abs(Int(ceil(CGFloat(newValue) * CGFloat(sections))))
        if self.currentSection != currentSection {
          if #available(iOS 10.0, *) {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
          }
          
          self.currentSection = currentSection
          delegate?.sectionChanged(slider: self, selected: currentSection)
          needsDisplay()
        }
      }
    }
  }
  
  private var currentSection: Int = 0
  
  private var color: UIColor = .yellow
  
  weak var delegate: SectionedSliderDelegate?
  
  // MARK: - Init
  
  public init(frame: CGRect, selectedSection: Int, sections: Int, halfSections: Bool, sliderColor: UIColor) {
    self.halfSections = halfSections
    super.init(frame: frame)
    
    backgroundColor = .clear
    layer.backgroundColor = UIColor.clear.cgColor
    
    self.sections = sections
    color = sliderColor
    factor = CGFloat(selectedSection) / CGFloat(sections)
    currentSection = selectedSection
    
    addPanGesture()
    needsDisplay()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    halfSections = true
    super.init(coder: aDecoder)
  }
  
  // MARK: - Lifecyle
  
  open override func draw(_ layer: CALayer, in ctx: CGContext) {
    super.draw(layer, in: ctx)
    
    UIGraphicsPushContext(ctx)
    ctx.clear(frame)
    drawSlider(frame: superview?.bounds ?? layer.frame, sections: sections, sliderColor: color)
    UIGraphicsPopContext()
  }
  
  // MARK: - Functions
  
  private func addPanGesture() {
    let gesture = UIPanGestureRecognizer(target: self, action: #selector(SectionedSlider.dragged(gesture:)))
    addGestureRecognizer(gesture)
  }
  
  public func isValidPoint(_ point: CGPoint) -> Bool {
    return bodyPath?.contains(point) ?? false
  }
  
  func needsDisplay() {
    layer.contentsScale = UIScreen.main.scale
    layer.setNeedsDisplay()
  }
  
  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    selectedSectionOnPreviousTouch = currentSection
    guard let touch = touches.first else { return }
    let point = touch.location(in: self)
    
    if isValidPoint(point) {
      process(point: point)
    }
  }
  
  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    if let previouslySelectedSection = selectedSectionOnPreviousTouch {
      let point = touch.location(in: self)
      if isValidPoint(point), previouslySelectedSection == currentSection {
        delegate?.doubleTapped(on: currentSection)
      }
    }
  }
  
  @objc private func dragged(gesture: UIPanGestureRecognizer) {
    process(point: gesture.location(in: self))
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
  }
  
  private func process(point: CGPoint) {
    var x = frame.height - point.y
    x = x < 0 ? -1 : (x > frame.height ? frame.height : x)
    let sectionHeight = frame.height / CGFloat(sections)
    let numberOfSection = Int(x / sectionHeight)
    
    if numberOfSection >= 0, numberOfSection < sections {
      factor = x / frame.height
    }
  }
  
  private func drawSlider(frame: CGRect,
                          sections: Int = 20,
                          sliderColor: UIColor) {
    let startAngle: CGFloat = 4.2 * .pi / 3
    let endAngle: CGFloat = 4.8 * .pi / 3
    
    drawBodyTriangle(frame: frame,
                     startAngle: startAngle,
                     endAngle: endAngle)
    
    drawSectionedTriangle(frame: frame,
                          fillColor: sliderColor,
                          startAngle: startAngle,
                          endAngle: endAngle,
                          currentSection: currentSection,
                          numberOfSections: sections)
  }
  
  private func drawBodyTriangle(frame: CGRect,
                                startAngle: CGFloat,
                                endAngle: CGFloat) {
    bodyPath = nil
    let centerPoint = CGPoint(x: frame.midX, y: frame.minY + frame.height)
    
    bodyPath = UIBezierPath()
    bodyPath?.addArc(withCenter: centerPoint,
                     radius: frame.height,
                     startAngle: startAngle,
                     endAngle: endAngle,
                     clockwise: true)
    bodyPath?.addLine(to: centerPoint)
    
    // Fill
    UIColor.clear.setFill()
    bodyPath?.fill()
  }
  
  private func drawSectionedTriangle(frame: CGRect,
                                     lineWidth: CGFloat = 0.5,
                                     fillColor: UIColor,
                                     startAngle: CGFloat,
                                     endAngle: CGFloat,
                                     currentSection: Int,
                                     numberOfSections: Int) {
    sliderPath = nil
    sliderBodyPath = nil
    let centerPoint = CGPoint(x: frame.midX, y: frame.maxY)
    
    let emptySpace = lineWidth * (halfSections ? CGFloat(numberOfSections / 2 - 1) : CGFloat(numberOfSections - 1))
    let heightOfVisibleSection: CGFloat = (frame.height - emptySpace) / CGFloat(numberOfSections)
    
    sliderPath = UIBezierPath()
    sliderBodyPath = UIBezierPath()
    
    let coef = Double(currentSection) / Double(numberOfSections)
    let resultComponent = convert(min1: 0, value1: coef, max1: 1.0, min2: 0.4, max2: 1.0)
    
    let resultColor = fillColor.withAlphaComponent(CGFloat(resultComponent))
    
    func calcStartY(index: Int) -> CGFloat {
      let slideSpace = CGFloat(index - 1) * heightOfVisibleSection
      let lineSpace = lineWidth * (halfSections ? CGFloat(Int((index - 1) / 2)) : CGFloat(index - 2))
      return slideSpace + lineSpace
    }
    
    if let path = (currentSection > 1) ? sliderPath : sliderBodyPath {
      drawFirstRoundedSection(with: centerPoint,
                              startAngle: startAngle, endAngle: endAngle,
                              sectionHeight: heightOfVisibleSection, fillColor: resultColor, lineWidth: lineWidth)
      
      let startPoint = CGPoint(x: centerPoint.x + calcStartY(index: 3) * cos(startAngle),
                               y: centerPoint.y + calcStartY(index: 3) * sin(startAngle))
      path.move(to: startPoint)
    }
    
    for i in 3...(numberOfSections - 1) {
      let startY = calcStartY(index: i)
      
      ((i > currentSection) ? sliderBodyPath : sliderPath)?.addArc(withCenter: centerPoint,
                                                                   radius: startY,
                                                                   startAngle: startAngle,
                                                                   endAngle: endAngle,
                                                                   clockwise: true)
      ((i > currentSection) ? sliderBodyPath : sliderPath)?.addArc(withCenter: centerPoint,
                                                                   radius: startY + heightOfVisibleSection,
                                                                   startAngle: endAngle,
                                                                   endAngle: startAngle,
                                                                   clockwise: false)
    }
    
    if let path = (numberOfSections > currentSection) ? sliderBodyPath : sliderPath {
      drawLastRoundedSection(in: path, with: centerPoint,
                             startAngle: startAngle, endAngle: endAngle,
                             sectionHeight: heightOfVisibleSection,
                             startY: calcStartY(index: numberOfSections))
    }
    
    // Fill
    UIColor(white: 0.0, alpha: 0.5).setFill()
    sliderBodyPath?.fill()
    
    // Fill
    resultColor.setFill()
    sliderPath?.fill()
  }
  
  private func offsetY(withPoints startPoint: CGPoint, centerPoint: CGPoint, endPoint: CGPoint, and radius: CGFloat) -> CGFloat {
    let corner = roundedCorner(withLines: startPoint, via: centerPoint, to: endPoint, radius: radius)
    return (centerPoint.y - (corner.centerPoint.y + radius))
  }
  
  private func drawFirstRoundedSection(with center: CGPoint,
                                       startAngle: CGFloat, endAngle: CGFloat,
                                       sectionHeight: CGFloat, fillColor: UIColor, lineWidth: CGFloat) {
    let startY = halfSections ? sectionHeight : sectionHeight - lineWidth
    let startY2 = sectionHeight * 2
    
    let p0 = CGPoint(x: center.x + startY * cos(endAngle), y: center.y + startY * sin(endAngle))
    let p1 = CGPoint(x: center.x + startY * cos(startAngle), y: center.y + startY * sin(startAngle))
    
    let p3 = CGPoint(x: center.x + startY2 * cos(endAngle), y: center.y + startY2 * sin(endAngle))
    let p4 = CGPoint(x: center.x + startY2 * cos(startAngle), y: center.y + startY2 * sin(startAngle))
    
    if let path2 = (currentSection > 1 ? sliderPath : sliderBodyPath) {
      path2.move(to: p3)
      path2.addLine(to: p0)
      path2.addArc(withCenter: center,
                   radius: sectionHeight, startAngle: endAngle, endAngle: startAngle, clockwise: false)
      path2.addLine(to: p4)
      path2.addArc(withCenter: center,
                   radius: startY2,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: true)
      path2.close()
    }
    
    let radius: CGFloat = sectionHeight * 0.3
    let corner = roundedCorner(withLines: p0, via: center, to: p1, radius: radius)
    if let path1 = (currentSection > 0 ? sliderPath : sliderBodyPath) {
      path1.move(to: p0)
      path1.addLine(to: CGPoint(x: corner.centerPoint.x + radius * cos(corner.startAngle),
                                y: corner.centerPoint.y + radius * sin(corner.startAngle)))
      path1.addArc(withCenter: corner.centerPoint,
                   radius: radius, startAngle: corner.startAngle, endAngle: corner.endAngle, clockwise: true)
      path1.addLine(to: p1)
      path1.addArc(withCenter: center,
                   radius: startY,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: true)
      path1.close()
    }
  }
  
  private func drawLastRoundedSection(in path: UIBezierPath, with center: CGPoint,
                                      startAngle: CGFloat, endAngle: CGFloat,
                                      sectionHeight: CGFloat, startY: CGFloat) {
    let radius = sectionHeight
    
    // Arc from p1 to p2
    path.addArc(withCenter: center, radius: startY,
                startAngle: startAngle, endAngle: endAngle, clockwise: true)
    
    // p2
    let alpha = endAngle
    let p2 = CGPoint(x: center.x + startY * cos(alpha), y: center.y + startY * sin(alpha))
    
    // p3 (center)
    let delta = alpha - CGFloat.pi * 1.525 // ~94.5º
    let p3 = CGPoint(x: p2.x + radius * cos(delta + CGFloat.pi), y: p2.y + radius * sin(delta + CGFloat.pi))
    path.addArc(withCenter: p3, radius: radius,
                startAngle: delta, endAngle: alpha, clockwise: false)
    
    // p4
    let p4 = CGPoint(x: p3.x + radius * cos(alpha), y: p3.y + radius * sin(alpha))
    let startAngle2 = atan((p4.y - center.y) / (p4.x - center.x))
    let endAngle2 = startAngle + (endAngle - startAngle2)
    
    let rad = sqrt(pow(p4.x - center.x, 2) + pow(p4.y - center.y, 2))
    
    // Arc from p4 to p5
    path.addArc(withCenter: center, radius: rad,
                startAngle: startAngle2, endAngle: endAngle2, clockwise: false)
    
    // p6 (center)
    let p6 = CGPoint(x: 2 * center.x - p3.x, y: p3.y)
    path.addArc(withCenter: CGPoint(x: p6.x, y: p6.y), radius: radius,
                startAngle: 3 * CGFloat.pi - alpha, endAngle: CGFloat.pi - delta, clockwise: false)
    
    // close() draw line p6-p1
    path.close()
  }
  
  private func roundedCorner(withLines from: CGPoint,
                             via: CGPoint,
                             to: CGPoint,
                             radius: CGFloat) -> CornerPoint {
    let fromAngle = atan2f(Float(via.y - from.y), Float(via.x - from.x))
    let toAngle = atan2f(Float(to.y - via.y), Float(to.x - via.x))
    
    let fromOffset = CGVector(dx: CGFloat(-sinf(fromAngle) * Float(radius)), dy: CGFloat(cosf(fromAngle) * Float(radius)))
    let toOffset = CGVector(dx: CGFloat(-sinf(toAngle) * Float(radius)), dy: CGFloat(cosf(toAngle) * Float(radius)))
    
    let x1 = from.x + fromOffset.dx
    let y1 = from.y + fromOffset.dy
    
    let x2 = via.x + fromOffset.dx
    let y2 = via.y + fromOffset.dy
    
    let x3 = via.x + toOffset.dx
    let y3 = via.y + toOffset.dy
    
    let x4 = to.x + toOffset.dx
    let y4 = to.y + toOffset.dy
    
    let intersectionX = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
    let intersectionY = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / ((x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4))
    
    let intersection = CGPoint(x: intersectionX, y: intersectionY)
    
    let corner = CornerPoint(centerPoint: intersection,
                             startAngle: CGFloat(fromAngle) - CGFloat.pi / 2,
                             endAngle: CGFloat(toAngle) - CGFloat.pi / 2)
    return corner
  }
  
  private func convert(min1: Double, value1: Double, max1: Double,
                       min2: Double, max2: Double) -> Double {
    return ((max2 - min2) / (max1 - min1)) * (value1 - min1) + min2
  }
}

struct CornerPoint {
  let centerPoint: CGPoint
  let startAngle: CGFloat
  let endAngle: CGFloat
}
