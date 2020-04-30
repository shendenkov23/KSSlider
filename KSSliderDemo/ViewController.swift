//
//  ViewController.swift
//  KSSliderDemo
//
//  Created by shendenkov23 on 18.01.2018.
//  Copyright © 2020 shendenkov23. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  // MARK: - Private

  private func openSliderController() {
    var palette = SliderPalette()
    palette.sliderColor = .red

    let sliderController = SliderController.sliderController(icon: nil,
                                                             title: "Demo title",
                                                             buttonTitle: "Save",
                                                             startValue: 5.2121313,
                                                             numberOfSections: 10,
                                                             halfSections: true,
                                                             divider: 1.0,
                                                             palette: palette,
                                                             blurStyle: .light)

    sliderController.delegate = self

    present(sliderController, animated: true, completion: nil)
  }
}

// MARK: - Actions

extension ViewController {
  @IBAction func btnShowPressed(_ sender: UIButton) {
    openSliderController()
  }
}

// MARK: -

extension ViewController: SliderControllerDelegate {
  func valueChanged(with value: Float) {
    print("Value changed:", value)
  }
}
