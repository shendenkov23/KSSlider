//
//  SliderController.swift
//  KSSliderDemo
//
//  Created by shendenkov23 on 18.01.2018.
//  Copyright © 2020 shendenkov23. All rights reserved.
//

import UIKit

public enum BlurStyle: Int {
  case none = -1
  case extraLight
  case light
  case dark
}

struct SliderPalette {
  var titleColor: UIColor = .black
  var valueColor: UIColor = .black
  var backgroundColor: UIColor = .white
  var sliderBodyColor: UIColor = .black
  var sliderColor: UIColor = .yellow
}

protocol SliderControllerDelegate: class {
  func valueChanged(with value: Float)
}

class SliderController: UIViewController {
  weak var delegate: SliderControllerDelegate?
  
  fileprivate var icon: UIImage?
  fileprivate var sliderTitle: String?
  fileprivate var saveButtonTitle: String?
  
  fileprivate(set) var divider: Float = 0.5
  fileprivate(set) var currentValue: Float = 1.0
  fileprivate(set) var numberOfSections: Int = 20
  fileprivate var halfSections: Bool = true
  
  fileprivate var blurStyle: BlurStyle = .light
  fileprivate var palette: SliderPalette = SliderPalette()
  
  fileprivate var slider: SectionedSlider?
  
  // MARK: - IBOutlets
  
  @IBOutlet fileprivate weak var imgIcon: UIImageView!
  @IBOutlet fileprivate weak var lblTitle: UILabel!
  @IBOutlet fileprivate weak var lblValue: UILabel!
  @IBOutlet fileprivate weak var sliderContainer: UIView!
  @IBOutlet fileprivate weak var btnSave: UIButton!
  
  // MARK: - Class func
  
  class func sliderController(icon: UIImage? = nil,
                              title: String? = nil,
                              buttonTitle: String? = nil,
                              startValue: Float = 1.0,
                              numberOfSections: Int = 10,
                              halfSections: Bool = true,
                              divider: Float = 0.5,
                              palette: SliderPalette? = nil,
                              blurStyle: BlurStyle = .light) -> SliderController {
    let storyboardName = "SliderController"
    let controllerId = "SliderController"
    
    let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle.main)
    let controller = storyboard.instantiateViewController(withIdentifier: controllerId) as! SliderController
    
    if let icon = icon {
      controller.icon = icon
    }
    if let title = title {
      controller.title = title
    }
    if let title = buttonTitle {
      controller.saveButtonTitle = title
    }
    
    controller.divider = divider
    // Round current value by divider
    let truncating = startValue.truncatingRemainder(dividingBy: divider)
    controller.currentValue = startValue - truncating + (truncating >= divider / 2.0 ? divider : 0.0)
    
    controller.halfSections = halfSections
    controller.numberOfSections = halfSections ? numberOfSections * 2 : numberOfSections
    
    if let palette = palette {
      controller.palette = palette
    }
    controller.blurStyle = blurStyle
    
    controller.transitioningDelegate = controller
    
    return controller
  }
  
  // MARK: - Init
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }
  
  private func commonInit() {
    modalPresentationStyle = .overCurrentContext
  }
  
  // MARK: - UIViewController overrides
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    prepareUI()
    slider = addStepSlider()
  }
  
  // MARK: -
  
  private func prepareUI() {
    if blurStyle == .none {
      view.backgroundColor = palette.backgroundColor
    } else {
      addBlurBackground()
    }
    
    lblTitle.text = title
    
    lblValue.text = (currentValue.truncatingRemainder(dividingBy: 1.0) == 0) ? "\(Int(currentValue))" : "\(currentValue)"
    
    btnSave.layer.cornerRadius = btnSave.frame.width * 0.5
    btnSave.backgroundColor = palette.sliderColor
    btnSave.layer.masksToBounds = true
    btnSave.setTitle(saveButtonTitle, for: .normal)
    
    if let icon = icon {
      imgIcon.image = icon
    } else {
      imgIcon.isHidden = true
    }
  }
  
  private func addBlurBackground() {
    view.backgroundColor = .clear
    
    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle(rawValue: blurStyle.rawValue) ?? .light)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = view.frame
    
    view.insertSubview(blurEffectView, at: 0)
  }
  
  private func addStepSlider() -> SectionedSlider {
    view.layoutIfNeeded()
    
    let section = Int(currentValue / divider)
    
    let slider = SectionedSlider(frame: sliderContainer.bounds,
                                 selectedSection: section,
                                 sections: numberOfSections,
                                 halfSections: halfSections,
                                 sliderColor: palette.sliderColor)
    slider.delegate = self
    sliderContainer.addSubview(slider)
    
    return slider
  }
  
  fileprivate func saveAndClose() {
    delegate?.valueChanged(with: currentValue)
    dismiss(animated: true, completion: nil)
  }
  
  // MARK: - IBActions
  
  @IBAction func btnSavePressed(_ sender: UIButton) {
    saveAndClose()
  }
  
  @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
    dismiss(animated: true, completion: nil)
  }
}

// MARK: - SectionedSlideDelegate

extension SliderController: SectionedSliderDelegate {
  func doubleTapped(on section: Int) {
    saveAndClose()
  }
  
  func sectionChanged(slider: SectionedSlider, selected: Int) {
    var value = Float(selected) * divider
    if halfSections {
      value /= 2
    }
    
    lblValue.text = (value.truncatingRemainder(dividingBy: 1.0) == 0) ? "\(Int(value))" : "\(value)"
    currentValue = value
  }
}

// MARK: - UIGestureRecognizerDelegate

extension SliderController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    let validity = slider?.isValidPoint(touch.location(in: slider)) ?? false
    return !validity
  }
}

// MARK: -

extension SliderController: UIViewControllerTransitioningDelegate {
  func animationController(forPresented presented: UIViewController,
                           presenting: UIViewController,
                           source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return CircularTransition(with: .present)
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return CircularTransition(with: .dismiss)
  }
}
