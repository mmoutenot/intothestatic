mongoose = require 'mongoose'
Schema = mongoose.Schema

videoSchema = mongoose.Schema
  id: Schema.Types.ObjectId
  instagram_id: String
  external_created_at: Date
  received_at:
    type: Date
    default: Date.now
  caption: String
  user:
    profile_picture: String
    username: String
    full_name: String
    id: String
  preview: String
  sources:
    hi: String
    lo: String
  location:
    latitude: Number
    longitude: Number
    name: String
  tags: Array

module.exports = mongoose.model('Video', videoSchema)
