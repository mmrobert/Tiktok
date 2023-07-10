//
//  CreateMediaViewController.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-11-26.
//

import Foundation
import UIKit
import AVFoundation
import Photos

class CreateMediaViewController: UIViewController {
    
    private struct Constants {
        static let maxRecordingTime: Int = 2 //  minutes
        
        static let leadingSpacing: CGFloat = 20
        static let trailingSpacing: CGFloat = 20
        static let topSpacing: CGFloat = 70
        static let bottomSpacing: CGFloat = 25
        
        static let resumeBtnHeight: CGFloat = 40
        static let resumeBtnWidth: CGFloat = 110
        static let btnBorderWidth: CGFloat = 1
        static let recordBtnSize: CGFloat = 90
        static let accBtnHeight: CGFloat = 43
        static let accBtnWidth: CGFloat = 51
    }
    
    enum DeviceSetupResult {
        case success
        case notAuthorized
    }
    
    private var previewView: CameraPreviewView = {
        let view = CameraPreviewView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.tabbarBackground
        return view
    }()
    
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = false
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = UIColor.white
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    
    private lazy var maxTimeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor.clear
        label.isUserInteractionEnabled = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()
    
    private lazy var recordButton: TimerRecordButton = {
        let button = TimerRecordButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    private lazy var cameraToggleButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.cameraToggle, for: .normal)
        return button
    }()
    
    private lazy var flashButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.flashLock, for: .normal)
        return button
    }()
    
    private lazy var galleryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.gallary, for: .normal)
        return button
    }()
    
    private lazy var resumeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.setTitle(String.resumeStr.localized(), for: .normal)
        button.setTitleColor(UIColor.yellow, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = Constants.resumeBtnHeight / 2
        button.layer.borderWidth = Constants.btnBorderWidth
        button.layer.borderColor = UIColor.yellow.cgColor
        button.layer.masksToBounds = true
        return button
    }()
    
    private var recordBtnState: TimerRecordButton.ButtonState = .disabled
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    private var movieFileOutput: AVCaptureMovieFileOutput?
    // Communicate with the session and other session objects on this queue
    // serial queue
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera,
                      .builtInDualCamera,
                      .builtInTrueDepthCamera,
                      .builtInDualWideCamera],
        mediaType: .video,
        position: .unspecified
    )
    private var keyValueObservations = [NSKeyValueObservation]()
    
    private var cameraTorchMode: CameraTorchMode = .off
    
    private var cameraSetupResult: DeviceSetupResult = .success
    private var microphoneSetupResult: DeviceSetupResult = .success
    
    private var albumManager: AlbumManager?
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    private var totalRecordTime: Int = 0  // seconds
    
    private let postMediaViewModel: PostMediaViewModel = PostMediaViewModel()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.tabbarBackground
        self.navigationController?.navigationBar.isTranslucent = true
        
        self.albumManager = AlbumManager(presenter: self)
        self.albumManager?.delegate = self
        
        cameraToggleButton.isEnabled = false
        flashButton.isEnabled = false
        resumeButton.isHidden = true
        recordButton.disable()
        
        self.removeAllTempFiles()
        
        self.setupUI()
        self.setupButtonActions()
        
        previewView.session = session
        previewView.cameraPreviewLayer.videoGravity = .resizeAspectFill
        
        self.checkCameraPermission()
        self.checkMicrophonePermission()
    }
    
    private func removeAllTempFiles() {
        var directory = NSTemporaryDirectory()
        sessionQueue.async {
            directory.removeAll()
        }
    }
    
    private func setupButtonActions() {
        self.cameraToggleButton.addTarget(self, action: #selector(CreateMediaViewController.changeCamera(_:)), for: .touchUpInside)
        self.flashButton.addTarget(self, action: #selector(CreateMediaViewController.changeFlash(_:)), for: .touchUpInside)
        self.galleryButton.addTarget(self, action: #selector(CreateMediaViewController.pickVideoFromGallery), for: .touchUpInside)
        self.resumeButton.addTarget(self, action: #selector(CreateMediaViewController.resumeInterruptedSession(_:)), for: .touchUpInside)
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                if !granted {
                    self?.cameraSetupResult = .notAuthorized
                } else {
                    self?.cameraSetupResult = .success
                }
                self?.sessionQueue.resume()
            })
        case .restricted:
            self.cameraSetupResult = .notAuthorized
        case .denied:
            self.cameraSetupResult = .notAuthorized
        case .authorized:
            self.cameraSetupResult = .success
        @unknown default:
            self.cameraSetupResult = .notAuthorized
        }
    }
    
    private func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { [weak self] granted in
                if !granted {
                    self?.microphoneSetupResult = .notAuthorized
                } else {
                    self?.microphoneSetupResult = .success
                }
                self?.sessionQueue.resume()
            })
        case .restricted:
            self.microphoneSetupResult = .notAuthorized
        case .denied:
            self.microphoneSetupResult = .notAuthorized
        case .authorized:
            self.microphoneSetupResult = .success
        @unknown default:
            self.microphoneSetupResult = .notAuthorized
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.checkCameraPermission()
        self.checkMicrophonePermission()
        sessionQueue.async { [weak self] in
            if self?.cameraSetupResult == .notAuthorized && self?.microphoneSetupResult == .notAuthorized {
                DispatchQueue.main.async {
                    let positiveAction = Action(title: String.settingsStr.localized()) { _ in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if let tabBarController = self?.tabBarController as? TabBarController {
                                tabBarController.chooseTab(appTab: .home)
                            }
                            UIApplication.shared.open(
                                settingsUrl,
                                options: [:],
                                completionHandler: nil
                            )
                        }
                    }
                    let negativeAction = Action(title: String.cancelStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.recordAVideoStr.localized(),
                        msg: String.accessToCameraAndMicrophoneStr.localized(),
                        positiveAction: positiveAction,
                        negativeAction: negativeAction
                    )
                }
            } else if self?.cameraSetupResult == .notAuthorized {
                DispatchQueue.main.async {
                    let positiveAction = Action(title: String.settingsStr.localized()) { _ in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if let tabBarController = self?.tabBarController as? TabBarController {
                                tabBarController.chooseTab(appTab: .home)
                            }
                            UIApplication.shared.open(
                                settingsUrl,
                                options: [:],
                                completionHandler: nil
                            )
                        }
                    }
                    let negativeAction = Action(title: String.cancelStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.recordAVideoStr.localized(),
                        msg: String.accessToCameraStr.localized(),
                        positiveAction: positiveAction,
                        negativeAction: negativeAction
                    )
                }
            } else if self?.microphoneSetupResult == .notAuthorized {
                DispatchQueue.main.async {
                    let positiveAction = Action(title: String.settingsStr.localized()) { _ in
                        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            if let tabBarController = self?.tabBarController as? TabBarController {
                                tabBarController.chooseTab(appTab: .home)
                            }
                            UIApplication.shared.open(
                                settingsUrl,
                                options: [:],
                                completionHandler: nil
                            )
                        }
                    }
                    let negativeAction = Action(title: String.cancelStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.recordAVideoStr.localized(),
                        msg: String.accessToMicrophoneStr.localized(),
                        positiveAction: positiveAction,
                        negativeAction: negativeAction
                    )
                }
            } else {
                self?.configureSession()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppGlobalVariables.shared.currentVC = .CreateMediaViewController
        sessionQueue.async { [weak self] in
            guard let sSelf = self else {
                return
            }
            if sSelf.cameraSetupResult == .success && sSelf.microphoneSetupResult == .success {
                sSelf.addObservers()
                sSelf.session.startRunning()
                sSelf.isSessionRunning = sSelf.session.isRunning
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async { [weak self] in
            guard let sSelf = self else { return }
            if sSelf.cameraSetupResult == .success && sSelf.microphoneSetupResult == .success {
                sSelf.session.stopRunning()
                sSelf.isSessionRunning = sSelf.session.isRunning
                sSelf.removeObservers()
            }
        }
        super.viewWillDisappear(animated)
    }
    
    override var shouldAutorotate: Bool {
        // Disable autorotation of the interface when recording is in progress.
        if let movieFileOutput = movieFileOutput {
            return !movieFileOutput.isRecording
        }
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.cameraPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }
    
    private func configureSession() {
        
        guard cameraSetupResult == .success && microphoneSetupResult == .success else {
            return
        }
        if session.inputs.count > 1 {
            return
        }
        session.beginConfiguration()
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.videoDeviceIsUnavailableStr.localized(),
                        msg: nil,
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                }
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                DispatchQueue.main.async { [weak self] in
                    guard let sSelf = self else { return }
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if sSelf.windowOrientation != .unknown {
                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: sSelf.windowOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    sSelf.previewView.cameraPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Couldn't add video device input to the session.")
                session.commitConfiguration()
                DispatchQueue.main.async { [weak self] in
                    let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.videoDeviceIsUnavailableStr.localized(),
                        msg: nil,
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                }
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            session.commitConfiguration()
            DispatchQueue.main.async { [weak self] in
                let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                self?.showAlert(
                    title: String.videoDeviceIsUnavailableStr.localized(),
                    msg: nil,
                    positiveAction: positiveAction,
                    negativeAction: nil
                )
            }
            return
        }
        
        // Add an audio input device.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
                DispatchQueue.main.async { [weak self] in
                    let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                    self?.showAlert(
                        title: String.audioDeviceIsUnavailableStr.localized(),
                        msg: nil,
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                }
            }
        } catch {
            print("Could not create audio device input: \(error)")
            DispatchQueue.main.async { [weak self] in
                let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                self?.showAlert(
                    title: String.audioDeviceIsUnavailableStr.localized(),
                    msg: nil,
                    positiveAction: positiveAction,
                    negativeAction: nil
                )
            }
        }
        
        // Add record output.
        let movieFileOutput = AVCaptureMovieFileOutput()
        
        if self.session.canAddOutput(movieFileOutput) {
            self.session.sessionPreset = .high
            self.session.addOutput(movieFileOutput)
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            self.movieFileOutput = movieFileOutput
            DispatchQueue.main.async { [weak self] in
                guard let sSelf = self else { return }
                if sSelf.isSessionRunning && sSelf.movieFileOutput != nil {
                    sSelf.recordButton.enable()
                } else {
                    sSelf.recordButton.disable()
                }
            }
        }
        session.commitConfiguration()
    }
    
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                self.cameraToggleButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
                self.flashButton.isEnabled = isSessionRunning
                if isSessionRunning && self.movieFileOutput != nil {
                    self.recordButton.enable()
                } else {
                    self.recordButton.disable()
                }
            }
        }
        keyValueObservations.append(keyValueObservation)
        
        let systemPressureStateObservation = observe(\.videoDeviceInput.device.systemPressureState, options: .new) { _, change in
            guard let systemPressureState = change.newValue else { return }
            self.setRecommendedFrameRateRangeForPressureState(systemPressureState: systemPressureState)
        }
        keyValueObservations.append(systemPressureStateObservation)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(subjectAreaDidChange),
            name: .AVCaptureDeviceSubjectAreaDidChange,
            object: videoDeviceInput.device
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionRuntimeError),
            name: .AVCaptureSessionRuntimeError,
            object: session
        )
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: session
        )
    }
    
    /// - Tag: HandleSystemPressure
    private func setRecommendedFrameRateRangeForPressureState(systemPressureState: AVCaptureDevice.SystemPressureState) {
        /*
         The frame rates used here are only for demonstration purposes.
         Your frame rate throttling may be different depending on your app's camera configuration.
         */
        let pressureLevel = systemPressureState.level
        if pressureLevel == .serious || pressureLevel == .critical {
            if self.movieFileOutput == nil || self.movieFileOutput?.isRecording == false {
                do {
                    try self.videoDeviceInput.device.lockForConfiguration()
                    print("Reached elevated system pressure level: \(pressureLevel). Throttling frame rate.")
                    self.videoDeviceInput.device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 20)
                    self.videoDeviceInput.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 15)
                    self.videoDeviceInput.device.unlockForConfiguration()
                } catch {
                    print("Could not lock device for configuration: \(error)")
                }
            }
        } else if pressureLevel == .shutdown {
            print("Session stopped running due to shutdown system pressure level.")
        }
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        sessionQueue.async { [weak self] in
            guard let sSelf = self else { return }
            let device = sSelf.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    /// - Tag: HandleRuntimeError
    @objc
    func sessionRuntimeError(notification: NSNotification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
        
        print("Capture session runtime error: \(error)")
        // If media services were reset, and the last start succeeded, restart the session.
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [weak self] in
                guard let sSelf = self else { return }
                if sSelf.isSessionRunning {
                    sSelf.session.startRunning()
                    sSelf.isSessionRunning = sSelf.session.isRunning
                } else {
                    DispatchQueue.main.async {
                        sSelf.resumeButton.isHidden = false
                    }
                }
            }
        } else {
            self.resumeButton.isHidden = false
        }
    }
    
    /// - Tag: HandleInterruption
    @objc
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios you want to enable the user to resume the session.
         For example, if music playback is initiated from Control Center while
         using this app, then the user can let the app resume
         the session running, which will stop music playback. Note that stopping
         music playback in Control Center will not automatically resume the session.
         Also note that it's not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
           let reasonIntegerValue = userInfoValue.integerValue,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            print("Capture session was interrupted with reason \(reason)")
            
            var showResumeButton = false
            if reason == .audioDeviceInUseByAnotherClient || reason == .videoDeviceInUseByAnotherClient {
                showResumeButton = true
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                // Fade-in a label to inform the user that the camera is unavailable.
            } else if reason == .videoDeviceNotAvailableDueToSystemPressure {
                print("Session stopped running due to shutdown system pressure level.")
            }
            if showResumeButton {
                // Fade-in a button to enable the user to try to resume the session running.
                resumeButton.alpha = 0
                resumeButton.isHidden = false
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.resumeButton.alpha = 1
                }
            }
        }
    }
    
    @objc
    func sessionInterruptionEnded(notification: NSNotification) {
        print("Capture session interruption ended")
        
        if !resumeButton.isHidden {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                self?.resumeButton.alpha = 0
            }, completion: { [weak self] _ in
                self?.resumeButton.isHidden = true
            })
        }
    }
    
    @objc
    private func changeCamera(_ cameraToggleButton: UIButton) {
        self.cameraToggleButton.isEnabled = false
        self.recordButton.disable()
        
        sessionQueue.async { [weak self] in
            guard let sSelf = self else { return }
            let currentVideoDevice = sSelf.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position

            let backVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            )
            let frontVideoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera],
                mediaType: .video,
                position: .front
            )
            var newVideoDevice: AVCaptureDevice? = nil
            
            switch currentPosition {
            case .unspecified, .front:
                newVideoDevice = backVideoDeviceDiscoverySession.devices.first
            case .back:
                newVideoDevice = frontVideoDeviceDiscoverySession.devices.first
            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                newVideoDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    sSelf.session.beginConfiguration()
                    // Remove the existing device input first, because AVCaptureSession doesn't support
                    // simultaneous use of the rear and front cameras.
                    sSelf.session.removeInput(sSelf.videoDeviceInput)
                    
                    if sSelf.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(sSelf, name: .AVCaptureDeviceSubjectAreaDidChange, object: currentVideoDevice)
                        NotificationCenter.default.addObserver(sSelf, selector: #selector(sSelf.subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
                        
                        sSelf.session.addInput(videoDeviceInput)
                        sSelf.videoDeviceInput = videoDeviceInput
                    } else {
                        sSelf.session.addInput(sSelf.videoDeviceInput)
                    }
                    
                    if let connection = sSelf.movieFileOutput?.connection(with: .video) {
                        sSelf.session.sessionPreset = .high
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    sSelf.session.commitConfiguration()
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                sSelf.cameraToggleButton.isEnabled = true
                sSelf.recordButton.enable()
            }
        }
    }
    
    @objc
    private func changeFlash(_ flashButton: UIButton) {
        self.cameraTorchMode = self.cameraTorchMode.nextMode()
        self.flashButton.setImage(self.cameraTorchMode.torchModeButtonImage(), for: .normal)
        self.flashButton.isEnabled = false
        recordButton.disable()
        
        sessionQueue.async { [weak self] in
            guard let sSelf = self else { return }
            let device = sSelf.videoDeviceInput.device
            if device.hasTorch {
                do {
                    try device.lockForConfiguration()
                    switch sSelf.cameraTorchMode {
                    case .on:
                        device.torchMode = AVCaptureDevice.TorchMode.on
                    case .off:
                        device.torchMode = AVCaptureDevice.TorchMode.off
                    }
                    device.unlockForConfiguration()
                } catch {
                    print("Torch could not be used")
                }
            } else {
                print("Torch is not available")
            }
            DispatchQueue.main.async {
                sSelf.flashButton.isEnabled = true
                sSelf.recordButton.enable()
            }
        }
    }
    
    @objc
    private func resumeInterruptedSession(_ resumeButton: UIButton) {
        sessionQueue.async { [weak self] in
            /*
             The session might fail to start running, for example, if a phone call is still
             using audio or video. This failure is communicated by the session posting a
             runtime error notification. To avoid repeatedly failing to start the session,
             only try to restart the session in the error handler if you aren't
             trying to resume the session.
             */
            guard let sSelf = self else { return }
            sSelf.session.startRunning()
            sSelf.isSessionRunning = sSelf.session.isRunning
            if !sSelf.session.isRunning {
                DispatchQueue.main.async {
                    let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
                    sSelf.showAlert(
                        title: String.unableToResumeVideoStr.localized(),
                        msg: nil,
                        positiveAction: positiveAction,
                        negativeAction: nil
                    )
                }
            } else {
                DispatchQueue.main.async {
                    sSelf.resumeButton.isHidden = true
                }
            }
        }
    }
    
    @objc
    private func pickVideoFromGallery() {
        self.albumManager?.presentVideoPickerViewController()
    }
    
    private func startRecording() {
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        let videoPreviewLayerOrientation = previewView.cameraPreviewLayer.connection?.videoOrientation
        sessionQueue.async {
            if !movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    // Marks the start of a task that should continue if the app enters the background
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                
                let availableVideoCodecTypes = movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
                
                // Start recording video to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                
                let fileURL = URL(fileURLWithPath: outputFilePath)
                let path = fileURL.path
                if FileManager.default.fileExists(atPath: path) {
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        print("Could not remove file at url: \(fileURL)")
                    }
                }
                movieFileOutput.startRecording(to: fileURL, recordingDelegate: self)
            }
        }
    }
    
    private func stopRecording() {
        guard let movieFileOutput = self.movieFileOutput else {
            return
        }
        sessionQueue.async {
            if movieFileOutput.isRecording {
                movieFileOutput.stopRecording()
            }
        }
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    private func showAlert(title: String?, msg: String?, positiveAction: Action?, negativeAction: Action?) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        if positiveAction != nil {
            let positiveHandler: (UIAlertAction) -> Void = { alertAction in
                positiveAction?.handler?(alertAction.title)
            }
            alert.addAction(UIAlertAction(title: positiveAction?.title, style: .default, handler: positiveHandler))
        }
        if negativeAction != nil {
            let negativeHandler: (UIAlertAction) -> Void = { alertAction in
                negativeAction?.handler?(alertAction.title)
            }
            alert.addAction(UIAlertAction(title: negativeAction?.title, style: .cancel, handler: negativeHandler))
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    deinit {
        print("🍎 CreateMediaViewController - deinit")
    }
}

extension CreateMediaViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Because we use a unique file path for each recording,
        // a new recording won't overwrite a recording mid-save.
        func cleanup() {
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        cleanup()
        
        guard error == nil else {
            print("Movie file finishing error: \(String(describing: error))")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            if sSelf.totalRecordTime > 0 {
                sSelf.presentVideoReview(outputFileURL: outputFileURL)
            }
        }
    }
    
    private func presentVideoReview(outputFileURL: URL) {
        self.postMediaViewModel.videoURL = outputFileURL
        let reviewVC = ReviewVideoViewController(postMediaViewModel: self.postMediaViewModel)
        reviewVC.hidesBottomBarWhenPushed = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.pushViewController(reviewVC, animated: true)
    }
}

// setup UI
extension CreateMediaViewController {
    
    private func setupUI() {
        self.view.addSubview(previewView)
        NSLayoutConstraint.activate(
            [previewView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
             previewView.topAnchor.constraint(equalTo: self.view.topAnchor),
             previewView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
             previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)]
        )
        
        self.previewView.addSubview(self.recordButton)
        self.recordButton.delegate = self
        self.recordButton.maxRecordingTime = Constants.maxRecordingTime
        self.recordButton.enable()
        NSLayoutConstraint.activate(
            [recordButton.centerXAnchor.constraint(equalTo: self.previewView.centerXAnchor, constant: 0),
             recordButton.widthAnchor.constraint(equalToConstant: Constants.recordBtnSize),
             recordButton.heightAnchor.constraint(equalToConstant: Constants.recordBtnSize),
             recordButton.bottomAnchor.constraint(equalTo: self.previewView.bottomAnchor, constant: -Constants.bottomSpacing)]
        )
        
        self.previewView.addSubview(self.maxTimeLabel)
        self.maxTimeLabel.text = String(format: String.maxRecordingTimeStr.localized(), String(Constants.maxRecordingTime))
        NSLayoutConstraint.activate(
            [maxTimeLabel.leadingAnchor.constraint(equalTo: self.previewView.leadingAnchor, constant: 50),
             maxTimeLabel.trailingAnchor.constraint(equalTo: self.previewView.trailingAnchor, constant: -50),
             maxTimeLabel.bottomAnchor.constraint(equalTo: self.recordButton.topAnchor, constant: -15)]
        )
        
        self.previewView.addSubview(self.timerLabel)
        NSLayoutConstraint.activate(
            [timerLabel.leadingAnchor.constraint(equalTo: self.previewView.leadingAnchor, constant: 50),
             timerLabel.trailingAnchor.constraint(equalTo: self.previewView.trailingAnchor, constant: -50),
             timerLabel.bottomAnchor.constraint(equalTo: self.maxTimeLabel.topAnchor, constant: 3)]
        )
        
        self.previewView.addSubview(self.galleryButton)
        NSLayoutConstraint.activate(
            [galleryButton.leadingAnchor.constraint(equalTo: self.recordButton.trailingAnchor, constant: 45),
             galleryButton.widthAnchor.constraint(equalToConstant: Constants.accBtnWidth),
             galleryButton.heightAnchor.constraint(equalToConstant: Constants.accBtnHeight),
             galleryButton.centerYAnchor.constraint(equalTo: self.recordButton.centerYAnchor, constant: 0)]
        )
        
        self.previewView.addSubview(self.resumeButton)
        NSLayoutConstraint.activate(
            [resumeButton.centerXAnchor.constraint(equalTo: self.previewView.centerXAnchor, constant: 0),
             resumeButton.widthAnchor.constraint(equalToConstant: Constants.resumeBtnWidth),
             resumeButton.heightAnchor.constraint(equalToConstant: Constants.resumeBtnHeight),
             resumeButton.centerYAnchor.constraint(equalTo: self.previewView.centerYAnchor, constant: 0)]
        )
        
        self.previewView.addSubview(self.cameraToggleButton)
        NSLayoutConstraint.activate(
            [cameraToggleButton.trailingAnchor.constraint(equalTo: self.previewView.trailingAnchor, constant: -Constants.trailingSpacing),
             cameraToggleButton.topAnchor.constraint(equalTo: self.previewView.topAnchor, constant: Constants.topSpacing),
             cameraToggleButton.widthAnchor.constraint(equalToConstant: Constants.accBtnWidth),
             cameraToggleButton.heightAnchor.constraint(equalToConstant: Constants.accBtnHeight)]
        )
        
        self.previewView.addSubview(self.flashButton)
        NSLayoutConstraint.activate(
            [flashButton.trailingAnchor.constraint(equalTo: self.previewView.trailingAnchor, constant: -Constants.trailingSpacing),
             flashButton.topAnchor.constraint(equalTo: self.cameraToggleButton.bottomAnchor, constant: 30),
             flashButton.widthAnchor.constraint(equalToConstant: Constants.accBtnWidth),
             flashButton.heightAnchor.constraint(equalToConstant: Constants.accBtnHeight)]
        )
    }
}

extension CreateMediaViewController: TimerRecordButtonDelegate {
    
    func tapButton(buttonState: TimerRecordButton.ButtonState) {
        switch buttonState {
        case .record:
            self.totalRecordTime = 0
            self.startRecording()
        case .stop(let totalSeconds):
            self.totalRecordTime = totalSeconds
            self.stopRecording()
        case .disabled:
            break
        }
    }
    
    func totalTimeStr(time: String) {
        self.timerLabel.text = time
    }
    
    func reachMaxTime(totalSeconds: Int) {
        self.totalRecordTime = totalSeconds
        self.stopRecording()
    }
}

extension CreateMediaViewController: AlbumManagerDelegate {
    
    func didFinishPicking(videoURL: URL) {
        
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration
        let durationTime = Int(CMTimeGetSeconds(duration))
        
        if durationTime > Constants.maxRecordingTime * 60 {
            let positiveAction = Action(title: String.OKStr.localized(), handler: nil)
            self.showAlert(
                title: String(format: String.maxRecordingTimeStr.localized(), String(Constants.maxRecordingTime)),
                msg: String(format: String.theSelectedVideoIsTooLongStr.localized(), String(Constants.maxRecordingTime)),
                positiveAction: positiveAction,
                negativeAction: nil
            )
        } else {
            self.presentVideoReview(outputFileURL: videoURL)
        }
    }
}
