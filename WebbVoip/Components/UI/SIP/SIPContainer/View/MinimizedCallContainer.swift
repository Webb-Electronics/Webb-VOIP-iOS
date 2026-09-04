import Foundation
import SwiftUI

struct MinimizedCallContainer<Content: View>: View {
    let vm: VideoCallPageVM?
    let video: Bool
    @ViewBuilder let containedView: Content

    var body: some View {
        GeometryReader { geometry in
            containedView
                .overlay(alignment: .topTrailing) {
                    if video {
                        OverlayVideoView(size: geometry.size, vm: vm) {
                            vm?.minimizeVideo = false
                        }
                    } else {
                        OverlayAudioView(size: geometry.size) {
                            vm?.minimizeVideo = false
                        }
                    }
                }
        }
    }
}

private struct OverlayAudioView: View {
    let size: CGSize
    let setterFunc: () -> Void
    var body: some View {
        HStack {
            Button {
                setterFunc()

            } label: {
                Image(systemName: "phone.connection.fill")
            }.padding()
                .background(Color.green)
                .clipShape(Circle()).font(.title)
                .foregroundColor(.white)

        }.position(CGPoint(x: size.width * 0.9, y: size.height * 0.8))
    }
}

private struct OverlayVideoView: View {
    let size: CGSize
    let vm: VideoCallPageVM?
    let setterFunc: () -> Void
    @State private var dragTo: CGPoint?
    var body: some View {
        (
            VideoScreenStream { view in
                vm?.updateCallViewSupplier(view)
            }
            .background(Color.gray)
            .overlay(alignment: .bottom) {
                Text("Tap Full Screen").foregroundStyle(.white)
            }
            .cornerRadius(10.0)
            .padding(EdgeInsets(top: 15, leading: 0, bottom: 0, trailing: 15))
            .frame(width: size.width / 2.8, height: size.height / 4)
            .animation(.default, value: dragTo)
            .position(
                dragTo ?? CGPoint(x: 1.6 * size.width / 2, y: 0.4 * size.height / 2))
            .highPriorityGesture(
                DragGesture()
                    .onChanged { value in
                        let left = (size.width / 5)
                        let right = (1.6 * size.width / 2)
                        let top = (0.4 * size.height / 2)
                        let bottom = (size.height / 1.25)
                        var valX = value.location.x
                        var valY = value.location.y
                        if abs(valX - left) < abs(valX - right) {
                            valX = left
                        } else {
                            valX = right
                        }
                        if abs(valY - top) < abs(valY - bottom) {
                            valY = top
                        } else {
                            valY = bottom
                        }
                        dragTo = CGPoint(x: valX, y: valY)
                    }
            )

        ).onTapGesture {
            setterFunc()
        }
    }
}
