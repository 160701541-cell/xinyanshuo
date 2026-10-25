extends RefCounted
class_name XianfanTravelPost

# Shared geography for schematics, in-person proximity and paid letters.
# Route durations are gameplay travel-time estimates, not kilometer claims.
const PLACES := [
    {"id":"home","name":"石桥村·家中","zone":"村","short":"家中"},
    {"id":"market","name":"石桥村·街口","zone":"村","short":"街口"},
    {"id":"river","name":"石桥村·溪边","zone":"村","short":"溪边"},
    {"id":"woods","name":"石桥村·林缘","zone":"村","short":"林缘"},
    {"id":"bookshop","name":"临安县城·旧书铺","zone":"城","short":"旧书铺"},
    {"id":"citymarket","name":"临安县城·东市","zone":"城","short":"东市"},
    {"id":"mountain","name":"青云山门·山门外","zone":"山","short":"山门"}
]
# The only known travel routes: button commands match world._act_core.
static func available_routes(place: String) -> Array[Dictionary]:
    match place:
        "石桥村·家中": return [
            {"to":"石桥村·街口","cmd":"去村口","minutes":12},
            {"to":"石桥村·溪边","cmd":"去溪边","minutes":18},
            {"to":"石桥村·林缘","cmd":"去林缘","minutes":24},
            {"to":"临安县城·东市","cmd":"去东市","minutes":115}]
        "石桥村·街口": return [
            {"to":"石桥村·家中","cmd":"回家","minutes":12},
            {"to":"石桥村·溪边","cmd":"去溪边","minutes":16}]
        "石桥村·溪边": return [
            {"to":"石桥村·家中","cmd":"回家","minutes":18},
            {"to":"石桥村·林缘","cmd":"去林缘","minutes":22},
            {"to":"石桥村·街口","cmd":"去村口","minutes":22}]
        "石桥村·林缘": return [
            {"to":"石桥村·家中","cmd":"回家","minutes":24},
            {"to":"石桥村·溪边","cmd":"去溪边","minutes":22}]
        "临安县城·东市": return [
            {"to":"临安县城·旧书铺","cmd":"回旧书铺","minutes":20},
            {"to":"石桥村·家中","cmd":"回石桥村","minutes":124},
            {"to":"青云山门·山门外","cmd":"沿山道北上","minutes":357}]
        "临安县城·旧书铺": return [
            {"to":"临安县城·东市","cmd":"去东市","minutes":20},
            {"to":"石桥村·家中","cmd":"回石桥村","minutes":124}]
        "青云山门·山门外": return []
    return []

static func zone(place: String) -> String:
    if place.begins_with("石桥村"): return "村"
    if place.begins_with("临安县城"): return "城"
    if place.begins_with("青云山门"): return "山"
    return ""

static func postage(origin: String, destination: String) -> Dictionary:
    var left:=zone(origin)
    var right:=zone(destination)
    if left.is_empty() or right.is_empty(): return {"ok":false,"reason":"地点尚未连入驿路，不能凭空寄信。"}
    # Physical route distance is represented by travel minutes; postman picks
    # up letters at service windows, so arrival is slower than direct walking.
    var minutes:=0
    if left==right:
        minutes=60 if origin!=destination else 30
    elif (left=="村" and right=="城") or (left=="城" and right=="村"):
        minutes=115
    elif (left=="山" and right=="城") or (left=="城" and right=="山"):
        minutes=357
    else:
        minutes=472
    var fee:=2 if left==right else (4 if minutes<=120 else (6 if minutes<=360 else 8))
    var delivery:=maxi(120,minutes*2+180)
    return {"ok":true,"fee":fee,"minutes":delivery,
        "route":"本地乡递" if left==right else ("村县驿递" if minutes<=120 else "山道递送"),
        "distance_game_minutes":minutes}

static func format_eta(minutes: int) -> String:
    var days:=int(minutes/1440)
    var hours:=int(ceili(float(minutes%1440)/60.0))
    return ("%d天"%days if days>0 else "")+("%d小时"%hours if hours>0 else "")
