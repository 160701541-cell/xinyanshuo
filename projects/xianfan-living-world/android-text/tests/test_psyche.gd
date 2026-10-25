extends SceneTree

var failures: Array[String]=[]
func check(ok: bool, why: String) -> void:
    if not ok: failures.append(why)
func _initialize() -> void:
    call_deferred("_run")

func _person(id: String, name: String, age: int, coins: int) -> Dictionary:
    return {"id":id,"name":name,"age":age,"coins":coins,"rations":3,
        "alive":true,"home":"石桥村·街口","work_place":"石桥村·街口",
        "place":"石桥村·街口","job":"手艺人","sector":"百工",
        "trait":"有独立人生","mood":"平静","hunger":0,
        "social":{},"biography":[]}

func _run() -> void:
    var people: Dictionary={
        "赵禾":_person("CIV100001","赵禾",26,20),
        "柳柳":_person("CIV100002","柳柳",23,1),
        "小石":_person("CIV100003","小石",16,8),
        "陆行":_person("CIV100004","陆行",32,12)
    }
    var society: Dictionary={"civic_agents":people,"civic_last_day":29,
        "civic_chronicle":[],"civic_life_events":[]}
    check(XianfanPsyche.ensure(society),"First load creates durable psychological profiles")
    check(not XianfanPsyche.ensure(society),"Second load preserves original identities and traits")
    for who in people:
        var mind: Dictionary=people[who]["psyche"]
        check(mind["traits"].size()==XianfanPsyche.TRAITS.size(),
            "All dimensions available to "+str(who))
    var stable_mind: Dictionary=people["赵禾"]["psyche"].duplicate(true)
    check(stable_mind["traits"]==XianfanPsyche._new_psyche(people["赵禾"])["traits"],
        "Same NPC identity yields same baseline temperament in different sessions")
    check(int(people["小石"]["psyche"]["traits"]["desire"])==0,
        "People under eighteen have no adult sexual mechanics")
    var giver: Dictionary=people["赵禾"]
    var recipient: Dictionary=people["柳柳"]
    giver["psyche"]["traits"]["compassion"]=90
    var before_total:=int(giver["coins"])+int(recipient["coins"])
    var aid:=XianfanPsyche.resolve(society,"赵禾","柳柳","help",30)
    check(bool(aid.get("ok",false)) and int(giver["coins"])==18 and int(recipient["coins"])==3,
        "Help must transfer actual funds, not mint wealth")
    check(int(giver["coins"])+int(recipient["coins"])==before_total,
        "Local aid must conserve money")
    check(int(recipient["social"].get("CIV100001",0))>0,
        "Recipient remembers assistance and attitude change")
    check(not bool(XianfanPsyche.resolve(society,"赵禾","柳柳","help",30).get("ok",false)),
        "Action cooldown stops repetitive farming")
    var offender: Dictionary=people["陆行"]
    offender["psyche"]["traits"]["greed"]=95
    offender["psyche"]["traits"]["self_control"]=5
    var private_cases_before: int=(society["psyche_cases"] as Array).size()
    var public_events_before: int=(society["civic_chronicle"] as Array).size()
    var pot_before:=int(offender["coins"])+int(giver["coins"])
    var theft:=XianfanPsyche.resolve(society,"陆行","赵禾","attempt_theft",34)
    check(bool(theft.get("ok",false)) and society["psyche_cases"].size()==private_cases_before+1,
        "Real greed may result in a documented private theft with a case id")
    check(int(offender["coins"])+int(giver["coins"])==pot_before,
        "Illicit transfer cannot create extra money")
    check(society["civic_chronicle"].size()==public_events_before,
        "Confidential accusations are not posted as established public scandal")
    check(not bool(society["psyche_cases"].back().get("suspect_public",true)),
        "Uninvestigated cases do not disclose an unproven suspect")
    check(not bool(XianfanPsyche.resolve(society,"陆行","小石","boundary_violation",35).get("ok",false)),
        "All coercive sexual boundary checks exclude minors")
    offender["psyche"]["traits"]["desire"]=90
    offender["psyche"]["traits"]["compassion"]=2
    var unlawful:=XianfanPsyche.resolve(society,"陆行","柳柳","boundary_violation",36)
    check(bool(unlawful.get("ok",false)) and
        bool(society["psyche_cases"].back().get("no_sexual_act_occurred",false)),
        "Serious boundary attempt is non-graphic, reportable and not sexual assault gameplay")
    check(society["civic_chronicle"].size()==public_events_before,
        "Survivor privacy is not turned into a public narration reward")
    check(int(recipient["psyche"]["stress"])>=15,
        "Psychological harm persists, instead of being erased by the next dialogue")
    giver["psyche"]["traits"]["desire"]=85
    giver["psyche"]["traits"]["self_control"]=90
    recipient["psyche"]["traits"]["attachment"]=90
    recipient["psyche"]["traits"]["caution"]=30
    recipient["psyche"]["stress"]=0
    var proposal:=XianfanPsyche.resolve(society,"赵禾","柳柳","express_interest",41)
    check(bool(proposal.get("ok",false)) and bool(proposal.get("accepted",false)),
        "Adult relationship interest requires independent recipient consent")
    recipient["psyche"]["traits"]["attachment"]=0
    var rejected:=XianfanPsyche.resolve(society,"赵禾","柳柳","express_interest",70)
    check(bool(rejected.get("ok",false)) and not bool(rejected.get("accepted",true)),
        "Refusal must override desire, familiarity and earlier acceptance")
    var minor_request:=XianfanPsyche.resolve(society,"赵禾","小石","express_interest",100)
    check(not bool(minor_request.get("ok",false)),
        "No adult romance actions involving minors, ever")
    recipient["home"]="临安县城·南巷"
    var distance:=XianfanPsyche.resolve(society,"赵禾","柳柳","express_interest",140)
    check(not bool(distance.get("ok",false)),
        "Characters must share a real place; no cross-county face-to-face activity")
    recipient["home"]="石桥村·街口"
    check(XianfanPsyche.advance_day(society,141)>=0,"Daily autonomous psychology runs offline")
    check(XianfanPsyche.advance_day(society,141)==0,
        "Same world day does not repeat autonomous NPC decisions")
    check(XianfanPsyche.ensure(society)==false,
        "Reload keeps relationship, case and personality records intact")
    check(people["赵禾"]["psyche"]["traits"]["compassion"]>=91,
        "Helping changes long-term character without rerolling the person")
    # Real credit: borrower requires voluntary lender, money moves once, due
    # date is enforceable, repayment restores money and affects trust.
    recipient["coins"]=1
    giver["psyche"]["traits"]["compassion"]=95
    var before_credit:=int(recipient["coins"])+int(giver["coins"])
    var loan:=XianfanPsyche.resolve(society,"柳柳","赵禾","borrow",142)
    check(bool(loan.get("ok",false)) and str(loan.get("kind",""))=="loan",
        "A poor NPC can seek consensual credit, not automatically seize money")
    check(int(recipient["coins"])+int(giver["coins"])==before_credit,
        "Loan principal must be conserved and carried by actual parties")
    check(society["psyche_debts"].size()==1 and
        int(society["psyche_debts"][0]["outstanding"])==3,
        "Individual loan agreement and date remain in authority database")
    XianfanPsyche.advance_day(society,150)
    check(str(society["psyche_debts"][0].get("status",""))=="overdue",
        "Unpaid loan remains in the world and becomes overdue")
    var repay:=XianfanPsyche.resolve(society,"柳柳","赵禾","repay",151)
    check(bool(repay.get("ok",false)) and
        str(society["psyche_debts"][0].get("status",""))=="repaid",
        "Full actual repayment clears an existing loan with a verifiable trail")
    check(int(recipient["coins"])+int(giver["coins"])==before_credit,
        "Repayment cannot create money")
    if failures.is_empty():
        print("PSYCHE TESTS PASS: personality persistence, adult consent, private reports, money conservation, time and location")
        quit(0)
        return
    for failure in failures: push_error("PSYCHE FAILURE: "+failure)
    quit(1)
