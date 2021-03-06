Conflict = require '../lib/conflict'
util = require './util'

describe "Conflict", ->

  describe 'a single two-way diff', ->
    [conflict] = []

    beforeEach ->
      editorView = util.openPath('single-2way-diff.txt')
      conflict = Conflict.all(editorView.getEditor())[0]

    it 'identifies the correct rows', ->
      expect(util.rowRangeFrom conflict.ours.marker).toEqual([1, 2])
      expect(conflict.ours.ref).toBe('HEAD')
      expect(util.rowRangeFrom conflict.theirs.marker).toEqual([3, 4])
      expect(conflict.theirs.ref).toBe('master')

    it 'finds the ref banners', ->
      expect(util.rowRangeFrom conflict.ours.refBannerMarker).toEqual([0, 1])
      expect(util.rowRangeFrom conflict.theirs.refBannerMarker).toEqual([4, 5])

    it 'finds the separator', ->
      expect(util.rowRangeFrom conflict.navigator.separatorMarker).toEqual([2, 3])

  it "finds multiple conflict markings", ->
    editorView = util.openPath('multi-2way-diff.txt')
    cs = Conflict.all(editorView.getEditor())

    expect(cs.length).toBe(2)
    expect(util.rowRangeFrom cs[0].ours.marker).toEqual([5, 7])
    expect(util.rowRangeFrom cs[0].theirs.marker).toEqual([8, 9])
    expect(util.rowRangeFrom cs[1].ours.marker).toEqual([14, 15])
    expect(util.rowRangeFrom cs[1].theirs.marker).toEqual([16, 17])

  describe 'sides', ->
    [editor, conflict] = []

    beforeEach ->
      editorView = util.openPath('single-2way-diff.txt')
      editor = editorView.getEditor()
      [conflict] = Conflict.all editor

    it 'retains a reference to conflict', ->
      expect(conflict.ours.conflict).toBe(conflict)
      expect(conflict.theirs.conflict).toBe(conflict)

    it 'remembers its initial text', ->
      editor.setCursorBufferPosition [1, 0]
      editor.insertText "I prefer this text! "

      expect(conflict.ours.originalText).toBe("These are my changes\n")

    it 'resolves as "ours"', ->
      conflict.ours.resolve()

      expect(conflict.resolution).toBe(conflict.ours)
      expect(conflict.ours.wasChosen()).toBe(true)
      expect(conflict.theirs.wasChosen()).toBe(false)

    it 'resolves as "theirs"', ->
      conflict.theirs.resolve()

      expect(conflict.resolution).toBe(conflict.theirs)
      expect(conflict.ours.wasChosen()).toBe(false)
      expect(conflict.theirs.wasChosen()).toBe(true)

    it 'broadcasts an event on resolution', ->
      resolved = false
      conflict.on "conflict:resolved", -> resolved = true
      conflict.ours.resolve()
      expect(resolved).toBe(true)

  describe 'navigator', ->
    [conflicts, navigator] = []

    beforeEach ->
      editorView = util.openPath('triple-2way-diff.txt')
      conflicts = Conflict.all(editorView.getEditor())
      navigator = conflicts[1].navigator

    it 'knows its conflict', ->
      expect(navigator.conflict).toBe(conflicts[1])

    it 'links to the previous conflict', ->
      expect(navigator.previous).toBe(conflicts[0])

    it 'links to the next conflict', ->
      expect(navigator.next).toBe(conflicts[2])

    it 'skips resolved conflicts', ->
      nav = conflicts[0].navigator
      conflicts[1].ours.resolve()
      expect(nav.nextUnresolved()).toBe(conflicts[2])

    it 'returns null at the end', ->
      nav = conflicts[2].navigator
      expect(nav.next).toBeNull()
      expect(nav.nextUnresolved()).toBeNull()
