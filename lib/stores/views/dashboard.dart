import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import '../../models/past_stream_data.dart';
import '../../types/classes/api/scene.dart';
import '../../types/classes/api/scene_item.dart';
import '../../types/classes/api/source_type.dart';
import '../../types/classes/api/stream_stats.dart';
import '../../types/classes/stream/events/base.dart';
import '../../types/classes/stream/events/scene_item_removed.dart';
import '../../types/classes/stream/events/scene_item_visibility_changed.dart';
import '../../types/classes/stream/events/source_mute_state_changed.dart';
import '../../types/classes/stream/events/source_renamed.dart';
import '../../types/classes/stream/events/source_volume_changed.dart';
import '../../types/classes/stream/events/switch_scenes.dart';
import '../../types/classes/stream/events/transition_begin.dart';
import '../../types/classes/stream/responses/base.dart';
import '../../types/classes/stream/responses/get_current_scene.dart';
import '../../types/classes/stream/responses/get_mute.dart';
import '../../types/classes/stream/responses/get_scene_list.dart';
import '../../types/classes/stream/responses/get_source_types_list.dart';
import '../../types/classes/stream/responses/get_special_sources.dart';
import '../../types/classes/stream/responses/get_volume.dart';
import '../../types/enums/event_type.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/request_type.dart';
import '../../utils/network_helper.dart';
import '../shared/network.dart';

part 'dashboard.g.dart';

class DashboardStore = _DashboardStore with _$DashboardStore;

abstract class _DashboardStore with Store {
  @observable
  bool isLive = false;
  @observable
  int goneLiveInMS;
  @observable
  PastStreamData streamData;
  @observable
  StreamStats latestStreamStats;

  @observable
  String activeSceneName;
  @observable
  ObservableList<Scene> scenes;

  /// WebSocket API will return all top level scene items for
  /// the current scene and elements of groups are inside the
  /// separate [SceneItem.groupChildren]. To better maintain and work
  /// with scene items, I flatten these so all scene items, even
  /// the children of groups are on top level and a the custom
  /// [SceneItem.displayGroup] propertry toggles whether they
  /// will be displayed or not, but this makes searching and
  /// updating scene items easier
  @observable
  ObservableList<SceneItem> currentSceneItems;

  @observable
  bool obsTerminated = false;

  @computed
  ObservableList<SceneItem> get currentSoundboardSceneItems =>
      this.currentSceneItems != null
          ? ObservableList.of(currentSceneItems.where((sceneItem) =>
              sceneItem.type == 'ffmpeg_source' && sceneItem.render))
          : ObservableList();

  @computed
  ObservableList<SceneItem> get currentAudioSceneItems =>
      this.currentSceneItems != null
          ? ObservableList.of(currentSceneItems.where((sceneItem) => this
              .sourceTypes
              .any((sourceType) =>
                  sourceType.caps.hasAudio &&
                  sourceType.typeID == sceneItem.type)))
          : ObservableList();

  @observable
  ObservableList<SceneItem> globalAudioSceneItems = ObservableList();

  @observable
  int sceneTransitionDurationMS;

  @observable
  bool isPointerOnTwitch = false;

  // Session activeSession;
  NetworkStore networkStore;

  List<SourceType> sourceTypes;

  void setupNetworkStoreHandling(NetworkStore networkStore) {
    this.networkStore = networkStore;
    this.initialRequests();
    this.handleStream();
  }

  void initialRequests() {
    NetworkHelper.makeRequest(
        this.networkStore.activeSession.socket, RequestType.GetSceneList);
    NetworkHelper.makeRequest(
        this.networkStore.activeSession.socket, RequestType.GetSourceTypesList);
    // NetworkHelper.makeRequest(
    //     this.networkStore.activeSession.socket, RequestType.GetSourcesList);
    // NetworkHelper.makeRequest(
    //     this.networkStore.activeSession.socket, RequestType.ListOutputs);
  }

  void handleStream() {
    this.networkStore.watchOBSStream().listen((message) {
      if (message is BaseEvent) {
        _handleEvent(message);
      } else {
        _handleResponse(message);
      }
    });
  }

  /// Check if we have an ongoing statistics going (!= null) and set it
  /// to null to indicate that we are done with this one and can start
  /// a new one
  Future<void> finishPastStreamData() async {
    if (this.streamData != null) {
      this.streamData = null;
    }
  }

  /// SceneItems which type is 'group' can have children which are
  /// SceneItems again - this would lead to checking those children
  /// in many cases (a lot of work and extra code). SO instead I flatten
  /// this by adding those children to the general list and since
  /// those children have their parent name as a property I can easily
  /// identify them in the flat list
  List<SceneItem> _flattenSceneItems(Iterable<SceneItem> sceneItems) {
    List<SceneItem> tmpSceneItems = [];
    sceneItems.forEach((sceneItem) {
      tmpSceneItems.add(sceneItem);
      if (sceneItem.groupChildren != null &&
          sceneItem.groupChildren.length > 0) {
        tmpSceneItems.addAll(sceneItem.groupChildren);
      }
    });
    return tmpSceneItems;
  }

  /// If we get a [StreamStatus] event and we have no [PastStreamData]
  /// instance (null) we need to check if we create a completely new
  /// instance (indicating new stream) or we use the last one since it
  /// seems as this is the same stream we already were connected to
  void _manageStreamDataInit() async {
    Box<PastStreamData> pastStreamDataBox =
        Hive.box<PastStreamData>(HiveKeys.PastStreamData.name);
    List<PastStreamData> tmp = pastStreamDataBox.values.toList();
    tmp.sort((a, b) => b.listEntryDateMS.last - a.listEntryDateMS.last);
    if (tmp.length > 0 &&
        DateTime.now().millisecondsSinceEpoch -
                this.latestStreamStats.totalStreamTime * 1000 <=
            tmp.last.listEntryDateMS.last) {
      this.streamData = tmp.last;
    } else {
      this.streamData = PastStreamData();
      await pastStreamDataBox.add(this.streamData);
    }
  }

  @action
  void setPointerOnTwitch(bool isPointerOnTwitch) =>
      this.isPointerOnTwitch = isPointerOnTwitch;

  @action
  void toggleSceneItemGroupVisibility(SceneItem sceneItem) {
    sceneItem.displayGroup = !sceneItem.displayGroup;
    this.currentSceneItems = ObservableList.of(this.currentSceneItems);
  }

  @action
  Future<void> _handleEvent(BaseEvent event) async {
    print(event.json['update-type']);
    switch (event.eventType) {
      case EventType.StreamStarted:
        this.isLive = true;
        this.goneLiveInMS = DateTime.now().millisecondsSinceEpoch;
        break;
      case EventType.StreamStopping:
        this.isLive = false;
        this.finishPastStreamData();
        break;
      case EventType.StreamStatus:
        this.latestStreamStats = StreamStats.fromJSON(event.json);
        if (this.goneLiveInMS == null) {
          this.isLive = true;
          this.goneLiveInMS = DateTime.now().millisecondsSinceEpoch -
              (this.latestStreamStats.totalStreamTime * 1000);
        }
        if (this.streamData == null) {
          _manageStreamDataInit();
        }
        this.streamData.addStreamStats(this.latestStreamStats);
        await this.streamData.save();
        break;
      case EventType.ScenesChanged:
        NetworkHelper.makeRequest(
            this.networkStore.activeSession.socket, RequestType.GetSceneList);
        break;
      case EventType.SwitchScenes:
        SwitchScenesEvent switchSceneEvent = SwitchScenesEvent(event.json);
        this.currentSceneItems =
            ObservableList.of(_flattenSceneItems(switchSceneEvent.sources));
        currentSceneItems.forEach((sceneItem) => NetworkHelper.makeRequest(
            this.networkStore.activeSession.socket,
            RequestType.GetMute,
            {'source': sceneItem.name}));

        break;
      case EventType.TransitionBegin:
        TransitionBeginEvent transitionBeginEvent =
            TransitionBeginEvent(event.json);
        this.sceneTransitionDurationMS = transitionBeginEvent.duration;
        this.activeSceneName = transitionBeginEvent.toScene;
        break;

      case EventType.SceneItemAdded:
        // SceneItemAddedEvent sceneItemAddedEvent =
        //     SceneItemAddedEvent(event.json);
        NetworkHelper.makeRequest(this.networkStore.activeSession.socket,
            RequestType.GetCurrentScene);
        break;
      case EventType.SceneItemRemoved:
        SceneItemRemovedEvent sceneItemRemovedEvent =
            SceneItemRemovedEvent(event.json);
        this.currentSceneItems.removeWhere(
            (sceneItem) => sceneItem.id == sceneItemRemovedEvent.itemID);
        break;
      case EventType.SourceRenamed:
        SourceRenamedEvent sourceRenamedEvent = SourceRenamedEvent(event.json);
        this
            .currentSceneItems
            .firstWhere((sceneItem) =>
                sceneItem.name == sourceRenamedEvent.previousName)
            .name = sourceRenamedEvent.newName;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        break;
      case EventType.SourceOrderChanged:
        print(event.json);
        // SourceOrderChangedEvent sourceOrderChangedEvent =
        //     SourceOrderChangedEvent(event.json);
        NetworkHelper.makeRequest(this.networkStore.activeSession.socket,
            RequestType.GetCurrentScene);
        break;
      case EventType.SourceVolumeChanged:
        SourceVolumeChangedEvent sourceVolumeChangedEvent =
            SourceVolumeChangedEvent(event.json);
        [...this.currentSceneItems, ...this.globalAudioSceneItems]
            .firstWhere((audioSceneItem) =>
                audioSceneItem.name == sourceVolumeChangedEvent.sourceName)
            .volume = sourceVolumeChangedEvent.volume;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        this.globalAudioSceneItems =
            ObservableList.of(this.globalAudioSceneItems);
        break;
      case EventType.SourceMuteStateChanged:
        SourceMuteStateChangedEvent sourceMuteStateChangedEvent =
            SourceMuteStateChangedEvent(event.json);
        [...this.currentSceneItems, ...this.globalAudioSceneItems]
            .firstWhere((audioSceneItem) =>
                audioSceneItem.name == sourceMuteStateChangedEvent.sourceName)
            .muted = sourceMuteStateChangedEvent.muted;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        this.globalAudioSceneItems =
            ObservableList.of(this.globalAudioSceneItems);
        break;
      case EventType.SceneItemVisibilityChanged:
        SceneItemVisibilityChangedEvent sceneItemVisibilityChangedEvent =
            SceneItemVisibilityChangedEvent(event.json);
        this
            .currentSceneItems
            .firstWhere((sceneItem) =>
                sceneItem.name == sceneItemVisibilityChangedEvent.itemName)
            .render = sceneItemVisibilityChangedEvent.itemVisible;

        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        break;
      case EventType.Exiting:
        await this.finishPastStreamData();
        this.obsTerminated = true;
        break;
      default:
        break;
    }
  }

  @action
  void _handleResponse(BaseResponse response) {
    switch (response.requestType) {
      case RequestType.GetSceneList:
        GetSceneListResponse getSceneListResponse =
            GetSceneListResponse(response.json);
        this.activeSceneName = getSceneListResponse.currentScene;
        this.scenes = ObservableList.of(getSceneListResponse.scenes);
        break;
      case RequestType.GetCurrentScene:
        GetCurrentSceneResponse getCurrentSceneResponse =
            GetCurrentSceneResponse(response.json);

        this.currentSceneItems = ObservableList.of(
            _flattenSceneItems(getCurrentSceneResponse.sources));
        this.currentSceneItems.forEach((sceneItem) => NetworkHelper.makeRequest(
            this.networkStore.activeSession.socket,
            RequestType.GetMute,
            {'source': sceneItem.name}));
        break;
      case RequestType.GetSpecialSources:
        GetSpecialSourcesResponse getSpecialSourcesResponse =
            GetSpecialSourcesResponse(response.json);
        if (getSpecialSourcesResponse.desktop1 != null) {
          NetworkHelper.makeRequest(
              this.networkStore.activeSession.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.desktop1});
        }
        if (getSpecialSourcesResponse.desktop2 != null) {
          NetworkHelper.makeRequest(
              this.networkStore.activeSession.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.desktop2});
        }
        if (getSpecialSourcesResponse.mic1 != null) {
          NetworkHelper.makeRequest(
              this.networkStore.activeSession.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic1});
        }
        if (getSpecialSourcesResponse.mic2 != null) {
          NetworkHelper.makeRequest(
              this.networkStore.activeSession.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic2});
        }
        if (getSpecialSourcesResponse.mic3 != null) {
          NetworkHelper.makeRequest(
              this.networkStore.activeSession.socket,
              RequestType.GetVolume,
              {'source': getSpecialSourcesResponse.mic3});
        }
        break;
      case RequestType.GetSourcesList:
        // GetSourcesListResponse getSourcesListResponse =
        //     GetSourcesListResponse(response.json);
        // getSourcesListResponse.sources.forEach((source) {
        //   print(response.json);
        // print('${source.name}: ${source.typeID}');
        // NetworkHelper.makeRequest(this.networkStore.activeSession.socket,
        //     RequestType.GetSourceSettings, {'sourceName': source.name});
        // });
        break;
      case RequestType.GetSourceTypesList:
        GetSourceTypesList getSourceTypesList =
            GetSourceTypesList(response.json);
        this.sourceTypes = getSourceTypesList.types;
        // (response.json['types'] as List<dynamic>)
        //     .forEach((type) => print(type['typeId']));
        NetworkHelper.makeRequest(this.networkStore.activeSession.socket,
            RequestType.GetCurrentScene);
        NetworkHelper.makeRequest(this.networkStore.activeSession.socket,
            RequestType.GetSpecialSources);
        break;
      case RequestType.GetVolume:
        GetVolumeResponse getVolumeResponse = GetVolumeResponse(response.json);
        if (this.globalAudioSceneItems.every((globalAudioItem) =>
            globalAudioItem.name != getVolumeResponse.name)) {
          this.globalAudioSceneItems.add(SceneItem.audio(
                name: getVolumeResponse.name,
                volume: getVolumeResponse.volume,
                muted: getVolumeResponse.muted,
              ));
        }
        break;
      case RequestType.GetMute:
        GetMuteResponse getMuteResponse = GetMuteResponse(response.json);
        this
            .currentSceneItems
            .firstWhere((sceneItem) => sceneItem.name == getMuteResponse.name)
            .muted = getMuteResponse.muted;
        this.currentSceneItems = ObservableList.of(this.currentSceneItems);
        break;
      case RequestType.GetSourceSettings:
        // GetSourceSettingsResponse getSourceSettingsResponse =
        //     GetSourceSettingsResponse(response.json);
        // print(
        //     '${getSourceSettingsResponse.sourceName}: ${getSourceSettingsResponse.sourceSettings}');
        break;
      case RequestType.ListOutputs:
        // ListOutputsResponse listOutputsResponse =
        //     ListOutputsResponse(response.json);
        // listOutputsResponse.outputs.forEach(
        //     (output) => print('${output.name}: ${output.flags.audio}'));
        break;
      default:
        break;
    }
  }
}
