import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: VideoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Corner Radius")
                .font(.headline)
            
            HStack {
                TextField("Radius", value: $viewModel.cornerRadius, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                
                Stepper("", value: $viewModel.cornerRadius, in: 0...viewModel.maxRadius, step: 1)
                    .labelsHidden()
            }
            
            Slider(value: $viewModel.cornerRadius, in: 0...viewModel.maxRadius)
            
            Spacer()
            
            if viewModel.isExporting {
                VStack(alignment: .leading) {
                    Text("Exporting... \(Int(viewModel.exportProgress * 100))%")
                    ProgressView(value: viewModel.exportProgress)
                }
                .padding(.bottom)
            }
            
            Button(action: {
                viewModel.exportVideo()
            }) {
                Label("Export Video", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.url == nil || viewModel.isExporting)
        }
        .padding()
        .frame(minWidth: 200)
    }
}
