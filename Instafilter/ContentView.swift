//
//  ContentView.swift
//  Instafilter
//
//  Created by Andres Marquez on 2021-07-30.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadious = 100.0
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    //Tracks name of selected filter
    @State private var filterSelection: String = "Change Filter"
    
    @State private var showingFilterSheet = false
    @State private var showNoImageAlert = false
    
    @State private var processedImage: UIImage?
    
    @State var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {self.filterIntensity},
            set: {self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        
        let radious = Binding<Double>(
            get: {self.filterRadious},
            set: {self.filterRadious = $0
                self.applyProcessing()
            }
        )
        
        NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }
                HStack {
                    Text("Intensity")
                    Slider(value: intensity)
                }
                .padding()
                
                HStack {
                    Text("Radious")
                    Slider(value: radious)
                }
                .padding()
                
                HStack {
                    Button(action: {
                        self.showingFilterSheet = true
                    }, label: {
                        Text("\(filterSelection)")
                    })
                    Spacer()
                    
                    Button("Save the picture") {
                        
                        if image != nil {
                            guard let processedImage = self.processedImage else { return }
                            
                            let imageSaver = ImageSaver()
                            
                            imageSaver.successHandler = { print("Success!") }
                            
                            imageSaver.errorHandler = { print("Opps \($0.localizedDescription)")}
                            
                            imageSaver.writeToPhotoAlbum(image: processedImage)
                        } else {
                            showNoImageAlert = true
                        }
                    }
                }
            }
            .padding([.horizontal,.bottom])
            .navigationBarTitle("Instafilter")
            //Image selector
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            //Filter selector
            .actionSheet(isPresented: $showingFilterSheet, content: {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystallize")) { self.setFilter(CIFilter.crystallize())
                        filterSelection = "Crystallize"
                    },
                    .default(Text("Edges")) {
                        self.setFilter(CIFilter.edges())
                        filterSelection = "Edges"
                    },
                    .default(Text("Gaussian Blur")) { self.setFilter(CIFilter.gaussianBlur())
                        filterSelection = "Blur"
                    },
                    .default(Text("Pixellate")) {
                        self.setFilter(CIFilter.pixellate())
                        filterSelection = "Pixellate"
                    },
                    .default(Text("Sepia Tone")) {
                        self.setFilter(CIFilter.sepiaTone())
                        filterSelection = "Sepia"
                    },
                    .default(Text("Unsharp Mask")) { self.setFilter(CIFilter.unsharpMask())
                        filterSelection = "Unsharp Mask"
                    },
                    .default(Text("Vignette")) {
                        self.setFilter(CIFilter.vignette())
                        filterSelection = "Vignette"
                    },
                    .cancel()
                ])
            })
            //Shows when trying to save a nil Image
            .alert(isPresented: $showNoImageAlert, content: {
                Alert(title: Text("No Image Selected"), message: Text("Please select an image to save"), dismissButton: .default(Text("OK")))
            })
        }
    }
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let begingImage = CIImage(image: inputImage)
        currentFilter.setValue(begingImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadious, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
        
        guard let outputImage = currentFilter.outputImage
        else {return}
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
