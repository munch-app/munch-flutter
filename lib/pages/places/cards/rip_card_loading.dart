// class RIPLoadingImageCard: RIPCard {
//    override func didLoad(data: PlaceData!) {
//        let shimmerView = FBShimmeringView()
//        let colorView = UIView()
//        colorView.backgroundColor = UIColor.whisper100
//        shimmerView.contentView = colorView
//        shimmerView.isShimmering = true
//        self.addSubview(shimmerView)
//
//        shimmerView.snp.makeConstraints { make in
//            make.height.equalTo(260).priority(.high)
//            make.edges.equalTo(self).inset(UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0))
//        }
//    }
//}
//
//class RIPLoadingNameCard: RIPCard {
//    override func didLoad(data: PlaceData!) {
//        let shimmerView = FBShimmeringView()
//        let colorView = UIView()
//        colorView.backgroundColor = UIColor.whisper100
//        shimmerView.contentView = colorView
//        shimmerView.isShimmering = true
//        shimmerView.layer.cornerRadius = 3
//        self.addSubview(shimmerView)
//
//        shimmerView.snp.makeConstraints { maker in
//            maker.height.equalTo(40).priority(.high)
//            maker.edges.equalTo(self).inset(UIEdgeInsets(topBottom: 12, leftRight: 24))
//        }
//    }
//}
//
//class RIPLoadingGalleryCard: RIPCard {
//    let indicator: NVActivityIndicatorView = {
//        let indicator = NVActivityIndicatorView(frame: .zero, type: .ballBeat, color: .secondary500, padding: 0)
//        return indicator
//    }()
//
//    override func didLoad(data: PlaceData!) {
//        self.backgroundColor = .white
//        self.addSubview(indicator)
//
//        indicator.startAnimating()
//        indicator.snp.makeConstraints { maker in
//            maker.height.equalTo(36).priority(.high)
//            maker.edges.equalTo(self).inset(24)
//        }
//    }
//}