//
//  CircularTransition.swift
//  KSSliderDemo
//
//  Created by shendenkov23 on 15.01.2018.
//  Copyright © 2020 shendenkov23. All rights reserved.
//

import UIKit

public enum CircularTransitionMode: Int {
  case present
  case dismiss
}

class CircularTransition: NSObject {
  var duration = 0.3
  fileprivate let transitionMode: CircularTransitionMode
  
  init(with mode: CircularTransitionMode) {
    transitionMode = mode
  }
}

extension CircularTransition: UIViewControllerAnimatedTransitioning {
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return duration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    let containerView = transitionContext.containerView
    
    switch transitionMode {
    case .present:
      if let presentedView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
        let viewCenter = presentedView.center
        
        presentedView.center = containerView.center
        presentedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        presentedView.alpha = 0
        
        containerView.addSubview(presentedView)
        
        UIView.animate(withDuration: duration, animations: {
          presentedView.transform = CGAffineTransform.identity
          presentedView.alpha = 1
          presentedView.center = viewCenter
          
        }, completion: { (success: Bool) in
          transitionContext.completeTransition(success)
        })
      }
      
    case .dismiss:
      let transitionModeKey = UITransitionContextViewKey.from
      
      if let returningView = transitionContext.view(forKey: transitionModeKey) {
        let viewCenter = returningView.center
        
        UIView.animate(withDuration: duration, animations: {
          returningView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
          returningView.center = containerView.center
          returningView.alpha = 0
          
        }, completion: { (success: Bool) in
          returningView.center = viewCenter
          returningView.removeFromSuperview()
          
          transitionContext.completeTransition(success)
        })
      }
    }
  }
}
