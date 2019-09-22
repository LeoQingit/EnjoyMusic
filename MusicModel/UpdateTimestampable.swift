//
//  UpdateTimestampable.swift
//  Music
//


let UpdateTimestampKey = "updatedAt"

protocol UpdateTimestampable: class {
    var updatedAt: Date { get set }
}

