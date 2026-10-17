import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app/theme/design_tokens.dart';

/// Claymorphism icon rendered from `assets/icons/` (user-made set).
///
/// IMPORTANT: clay SVGs are multicolor (gradients, highlights, shadows).
/// Do NOT apply a [ColorFilter] here — `srcIn` would flatten every icon to
/// a single silhouette and destroy the clay look. The optional [color] is
/// only a tint fallback for monochrome callers, off by default.
class NeuSvgIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? tint;
  final String? tooltip;

  const NeuSvgIcon(
    this.asset, {
    super.key,
    this.size = NeuTokens.iconMd,
    this.tint,
    this.tooltip,
  });

  /// Resolve a Material icon name (e.g. `pets`, `arrow_back_rounded`) to the
  /// clay asset via [SvgIcons.assetForMaterial]. Returns null when the pack
  /// has no equivalent — see `assets/icons/icon-map.json` `not_in_this_pack`.
  factory NeuSvgIcon.fromMaterial(
    String materialName, {
    double size = NeuTokens.iconMd,
    Color? tint,
    String? tooltip,
  }) {
    final asset = SvgIcons.assetForMaterial(materialName);
    if (asset == null) {
      throw ArgumentError('No clay icon for Material name: $materialName');
    }
    return NeuSvgIcon(asset, size: size, tint: tint, tooltip: tooltip);
  }

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: tint == null
          ? null
          : ColorFilter.mode(tint!, BlendMode.srcIn),
      semanticsLabel: tooltip,
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: icon);
    }
    return icon;
  }
}

/// Renders the clay SVG when the pack covers [materialName], otherwise falls
/// back to the legacy Material [Icon]. Lets migration proceed file-by-file
/// without breaking the ~62 names in `not_in_this_pack`.
class ClayIconOrMaterial extends StatelessWidget {
  final String materialName;
  final IconData fallback;
  final double size;
  final Color? color;

  const ClayIconOrMaterial(
    this.materialName, {
    super.key,
    required this.fallback,
    this.size = NeuTokens.iconMd,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final asset = SvgIcons.assetForMaterial(materialName);
    if (asset != null) {
      return NeuSvgIcon(asset, size: size);
    }
    return Icon(fallback, size: size, color: color);
  }
}

/// Asset paths for the user-made clay set in `assets/icons/`.
/// Source of truth for names: `assets/icons/icon-map.json` (`maps_to`).
abstract final class SvgIcons {
  static const _p = 'assets/icons/';

  static const accountSettings = '${_p}account-settings.svg';
  static const add = '${_p}add.svg';
  static const alert = '${_p}alert.svg';
  static const ambulance = '${_p}ambulance.svg';
  static const analytics = '${_p}analytics.svg';
  static const archive = '${_p}archive.svg';
  static const assignment = '${_p}assignment.svg';
  static const attach = '${_p}attach.svg';
  static const back = '${_p}back.svg';
  static const badge = '${_p}badge.svg';
  static const barcode = '${_p}barcode.svg';
  static const bathtub = '${_p}bathtub.svg';
  static const bird = '${_p}bird.svg';
  static const block = '${_p}block.svg';
  static const bloodDrop = '${_p}blood-drop.svg';
  static const bolt = '${_p}bolt.svg';
  static const bone = '${_p}bone.svg';
  static const brush = '${_p}brush.svg';
  static const cake = '${_p}cake.svg';
  static const calendar = '${_p}calendar.svg';
  static const camera = '${_p}camera.svg';
  static const carrier = '${_p}carrier.svg';
  static const cat = '${_p}cat.svg';
  static const category = '${_p}category.svg';
  static const certificate = '${_p}certificate.svg';
  static const chat = '${_p}chat.svg';
  static const check = '${_p}check.svg';
  static const chevronDown = '${_p}chevron-down.svg';
  static const chevronRight = '${_p}chevron-right.svg';
  static const close = '${_p}close.svg';
  static const cloudOff = '${_p}cloud-off.svg';
  static const copy = '${_p}copy.svg';
  static const delete = '${_p}delete.svg';
  static const dog = '${_p}dog.svg';
  static const doneAll = '${_p}done-all.svg';
  static const door = '${_p}door.svg';
  static const download = '${_p}download.svg';
  static const edit = '${_p}edit.svg';
  static const email = '${_p}email.svg';
  static const error = '${_p}error.svg';
  static const eventAvailable = '${_p}event-available.svg';
  static const eventBusy = '${_p}event-busy.svg';
  static const eventRepeat = '${_p}event-repeat.svg';
  static const female = '${_p}female.svg';
  static const filter = '${_p}filter.svg';
  static const flag = '${_p}flag.svg';
  static const folder = '${_p}folder.svg';
  static const foodBowl = '${_p}food-bowl.svg';
  static const forward = '${_p}forward.svg';
  static const globe = '${_p}globe.svg';
  static const heart = '${_p}heart.svg';
  static const heartPulse = '${_p}heart-pulse.svg';
  static const help = '${_p}help.svg';
  static const home = '${_p}home.svg';
  static const idTag = '${_p}id-tag.svg';
  static const image = '${_p}image.svg';
  static const info = '${_p}info.svg';
  static const inventory = '${_p}inventory.svg';
  static const lab = '${_p}lab.svg';
  static const link = '${_p}link.svg';
  static const listNumbered = '${_p}list-numbered.svg';
  static const location = '${_p}location.svg';
  static const lock = '${_p}lock.svg';
  static const lockReset = '${_p}lock-reset.svg';
  static const login = '${_p}login.svg';
  static const logout = '${_p}logout.svg';
  static const male = '${_p}male.svg';
  static const medication = '${_p}medication.svg';
  static const microchip = '${_p}microchip.svg';
  static const microscope = '${_p}microscope.svg';
  static const money = '${_p}money.svg';
  static const moon = '${_p}moon.svg';
  static const more = '${_p}more.svg';
  static const note = '${_p}note.svg';
  static const notifications = '${_p}notifications.svg';
  static const numbers = '${_p}numbers.svg';
  static const otherPet = '${_p}other-pet.svg';
  static const palette = '${_p}palette.svg';
  static const paw = '${_p}paw.svg';
  static const pawHeart = '${_p}paw-heart.svg';
  static const pending = '${_p}pending.svg';
  static const people = '${_p}people.svg';
  static const person = '${_p}person.svg';
  static const personAdd = '${_p}person-add.svg';
  static const personOff = '${_p}person-off.svg';
  static const phone = '${_p}phone.svg';
  static const pillBottle = '${_p}pill-bottle.svg';
  static const play = '${_p}play.svg';
  static const prescription = '${_p}prescription.svg';
  static const print = '${_p}print.svg';
  static const qrCode = '${_p}qr-code.svg';
  static const queue = '${_p}queue.svg';
  static const rabbit = '${_p}rabbit.svg';
  static const radioChecked = '${_p}radio-checked.svg';
  static const radioUnchecked = '${_p}radio-unchecked.svg';
  static const receipt = '${_p}receipt.svg';
  static const refresh = '${_p}refresh.svg';
  static const remove = '${_p}remove.svg';
  static const reorder = '${_p}reorder.svg';
  static const reptile = '${_p}reptile.svg';
  static const ruler = '${_p}ruler.svg';
  static const save = '${_p}save.svg';
  static const scan = '${_p}scan.svg';
  static const schedule = '${_p}schedule.svg';
  static const scissors = '${_p}scissors.svg';
  static const search = '${_p}search.svg';
  static const searchOff = '${_p}search-off.svg';
  static const send = '${_p}send.svg';
  static const settings = '${_p}settings.svg';
  static const share = '${_p}share.svg';
  static const shieldCheck = '${_p}shield-check.svg';
  static const skipNext = '${_p}skip-next.svg';
  static const sparkles = '${_p}sparkles.svg';
  static const star = '${_p}star.svg';
  static const stethoscope = '${_p}stethoscope.svg';
  static const success = '${_p}success.svg';
  static const swap = '${_p}swap.svg';
  static const textField = '${_p}text-field.svg';
  static const thermometer = '${_p}thermometer.svg';
  static const ticket = '${_p}ticket.svg';
  static const toggle = '${_p}toggle.svg';
  static const tooth = '${_p}tooth.svg';
  static const toyBall = '${_p}toy-ball.svg';
  static const treatment = '${_p}treatment.svg';
  static const truck = '${_p}truck.svg';
  static const unarchive = '${_p}unarchive.svg';
  static const upload = '${_p}upload.svg';
  static const vaccination = '${_p}vaccination.svg';
  static const visibility = '${_p}visibility.svg';
  static const visibilityOff = '${_p}visibility-off.svg';
  static const visit = '${_p}visit.svg';
  static const volume = '${_p}volume.svg';
  static const weightScale = '${_p}weight-scale.svg';
  static const xray = '${_p}xray.svg';

  /// Material-name → clay asset. Mirrors `assets/icons/icon-map.json`.
  /// Strips `_outlined` / `_outline` / `_rounded` / `_sharp` / `_filled`
  /// suffixes before lookup, looping until stable — so `info_outline_rounded`
  /// resolves via `info` and `check_circle_outline` via `check_circle`.
  static String? assetForMaterial(String materialName) {
    var base = materialName;
    while (true) {
      final stripped = base.replaceFirst(
        RegExp(r'_(outlined|outline|rounded|sharp|filled)$'),
        '',
      );
      if (stripped == base) break;
      base = stripped;
    }
    return _materialMap[base] ?? _materialMap[materialName];
  }

  static const _materialMap = <String, String>{
    'access_time': schedule,
    'add': add,
    'add_circle': add,
    'add_circle_outline': add,
    'alert': alert,
    'alternate_email': email,
    'archive': archive,
    'arrow_back': back,
    'arrow_back_ios_new': back,
    'arrow_drop_down': chevronDown,
    'arrow_forward': forward,
    'arrow_forward_ios': forward,
    'attach_file': attach,
    'attachment': attach,
    'bird': bird,
    'bolt': bolt,
    'calendar_month': calendar,
    'calendar_today': calendar,
    'cake': cake,
    'camera_alt': camera,
    'cancel': error,
    'cat': cat,
    'category': category,
    'check': check,
    'check_circle': success,
    'check_circle_outline': success,
    'chevron_down': chevronDown,
    'chevron_right': chevronRight,
    'clear': close,
    'clear_all': close,
    'close': close,
    'delete_forever': delete,
    'delete_outline': delete,
    'delete_sweep': delete,
    'description': note,
    'document_scanner': scan,
    'dog': dog,
    'edit': edit,
    'email': email,
    'error': error,
    'error_outline': error,
    'event': calendar,
    'event_available': eventAvailable,
    'exit_to_app': logout,
    'expand_more': chevronDown,
    'female': female,
    'filter_list': filter,
    'flag': flag,
    'flash_on': bolt,
    'format_list_numbered': listNumbered,
    'healing': treatment,
    'history': schedule,
    'home': home,
    'image': image,
    'info': info,
    'insert_drive_file': note,
    'inventory': inventory,
    'inventory_2': inventory,
    'keyboard_arrow_down': chevronDown,
    'lab': lab,
    'local_hospital': visit,
    'location_on': location,
    'lock': lock,
    'login': login,
    'logout': logout,
    'male': male,
    'mark_email_read': email,
    'mark_email_unread': email,
    'medical_information': prescription,
    'medical_services': visit,
    'medication': medication,
    'monitor_weight': weightScale,
    'more_vert': more,
    'nfc': microchip,
    'note': note,
    'note_alt': prescription,
    'notes': note,
    'notifications': notifications,
    'notifications_active': notifications,
    'notifications_none': notifications,
    'other-pet': otherPet,
    'palette': palette,
    'people': people,
    'people_outline': people,
    'person': person,
    'person_outline': person,
    'pets': paw,
    'photo_library': image,
    'prescription': prescription,
    'priority_high': alert,
    'rabbit': rabbit,
    'refresh': refresh,
    'reptile': reptile,
    'save': save,
    'scanner': scan,
    'schedule': schedule,
    'science': lab,
    'search': search,
    'settings': settings,
    'success': success,
    'task_alt': success,
    'timer': schedule,
    'title': note,
    'treatment': treatment,
    'tune': filter,
    'unarchive': unarchive,
    'update': refresh,
    'vaccination': vaccination,
    'vaccines': vaccination,
    'visibility': visibility,
    'visibility_off': visibilityOff,
    'visit': visit,
    'warning': alert,
    'warning_amber': alert,
  };
}
