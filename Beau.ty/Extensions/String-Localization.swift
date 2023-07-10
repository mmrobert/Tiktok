//
//  String-Localization.swift
//  Beau.ty
//  Created by Boqian Cheng on 2022-11-26.
//

import Foundation

extension String {
    
    static let homeStr = "Home"
    static let favoritesStr = "Favorites"
    static let postStr = "Post"
    static let inboxStr = "Inbox"
    static let profileStr = "Profile"
    static let maxRecordingTimeStr = "Max recording time"
    static let OKStr = "OK"
    static let cancelStr = "Cancel"
    static let recordAVideoStr = "Record a Video"
    static let accessToCameraAndMicrophoneStr = "Access to camera and microphone"
    static let accessToCameraStr = "Access to camera"
    static let accessToMicrophoneStr = "Access to microphone"
    static let settingsStr = "Settings"
    static let videoDeviceIsUnavailableStr = "Video Device is Unavailable"
    static let audioDeviceIsUnavailableStr = "Audio Device is Unavailable"
    static let resumeStr = "Resume"
    static let unableToResumeVideoStr = "Unable to Resume Video"
    static let theSelectedVideoIsTooLongStr = "The selected video is too long"
    static let discardTheVideoStr = "Discard the Video"
    static let discardTheVideoDetailsStr = "Discard the Video Details"
    static let discardStr = "Discard"
    static let nextStr = "Next"
    static let postVideoStr = "Post Video"
    static let addKeywordForSearchStr = "Add keyword for search"
    static let hashtagsStr = "Hashtags"
    static let broadcastLinkStr = "Broadcast Link"
    static let uploadingStr = "Uploading"
    static let uploadingFailedStr = "Uploading Failed"
    static let pleaseReuploadFromProfileStr = "Please re-upload from Profile"
    static let doneStr = "Done"
    static let uploadedSuccessfullyStr = "Uploaded Successfully"
    static let networkErrorStr = "Network Error"
    
    
    
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}
