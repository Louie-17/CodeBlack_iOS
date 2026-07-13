//
//  AppFont.swift
//  CodeBlack
//
//  타이포그래피 시스템 (Noto Sans KR).
//  디자인 스펙: heading = SemiBold, 그 외(subtitle/body/button/caption) = Medium.
//
//  사용법 — 한 줄로 호출:
//      Text("응급 병원 찾기").font(.heading1)
//      Text("환자 상태").font(.subtitle2)
//      Text("전송").font(.button1)
//
//  ※ 앱 시작 시 CodeBlackApp.init 에서 AppFont.register() 가 1회 호출되어야 한다.
//  ※ 크기는 디자인 스펙(px)을 pt로 고정한다. Dynamic Type 스케일이 필요하면
//    Font.custom(_:size:relativeTo:) 로 확장하면 된다.
//

import SwiftUI
import CoreText

enum AppFont {

    /// 번들 커스텀 폰트 파일명(확장자 제외). 동기화 그룹에 의해 앱 번들 리소스로 포함된다.
    private static let files = ["NotoSansKR-Medium", "NotoSansKR-SemiBold"]

    /// 앱 시작 시 1회 호출. 번들에 포함된 Noto Sans KR 폰트를 런타임 등록한다.
    static func register() {
        for file in files {
            guard let url = Bundle.main.url(forResource: file, withExtension: "ttf") else {
                assertionFailure("폰트 파일을 찾지 못함: \(file).ttf (타깃 리소스에 포함됐는지 확인)")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error),
               let err = error?.takeUnretainedValue() {
                // 이미 등록된 경우도 실패로 잡히므로 디버그 로그만 남긴다.
                let code = CFErrorGetCode(err)
                if code != CTFontManagerError.alreadyRegistered.rawValue {
                    print("폰트 등록 실패 [\(file)]: \(err)")
                }
            }
        }
    }

    /// 굵기별 PostScript 이름.
    fileprivate enum Weight {
        case medium, semibold
        var postScriptName: String {
            switch self {
            case .medium:   return "NotoSansKR-Medium"
            case .semibold: return "NotoSansKR-SemiBold"
            }
        }
    }
}

extension Font {

    private static func notoSansKR(_ size: CGFloat, _ weight: AppFont.Weight) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    // MARK: heading — SemiBold
    static let heading1 = notoSansKR(32, .semibold)
    static let heading2 = notoSansKR(28, .semibold)
    static let heading3 = notoSansKR(24, .semibold)
    static let heading4 = notoSansKR(22, .semibold)
    static let heading5 = notoSansKR(20, .semibold)
    static let heading6 = notoSansKR(18, .semibold)

    // MARK: subtitle — Medium
    static let subtitle1 = notoSansKR(24, .medium)
    static let subtitle2 = notoSansKR(22, .medium)
    static let subtitle3 = notoSansKR(20, .medium)
    static let subtitle4 = notoSansKR(18, .medium)

    // MARK: body — Medium
    static let body1 = notoSansKR(24, .medium)
    static let body2 = notoSansKR(22, .medium)
    static let body3 = notoSansKR(20, .medium)
    static let body4 = notoSansKR(18, .medium)
    static let body5 = notoSansKR(16, .medium)

    // MARK: button — Medium
    static let button1 = notoSansKR(22, .medium)
    static let button2 = notoSansKR(20, .medium)
    static let button3 = notoSansKR(18, .medium)
    static let button4 = notoSansKR(16, .medium)
    static let button5 = notoSansKR(14, .medium)

    // MARK: caption — Medium
    static let caption1 = notoSansKR(20, .medium)
    static let caption2 = notoSansKR(18, .medium)
    static let caption3 = notoSansKR(16, .medium)
    static let caption4 = notoSansKR(14, .medium)
}
