local this = {}

this.forbiddenIds = {
    ["war_axe_airan_ammu"] = true,
    ["shadow_shield"] = true,
    ["bonebiter_bow_unique"] = true,
    ["heart_of_fire"] = true,
    ["t_wereboarrobe"] = true,
    ["werewolfrobe"] = true,


    ["vivec_god"] = true,
    ["wraith_sul_senipul"] = true,

    ["toddtest"] = true,

    ["werewolfhead"] = true,
    --morrowind quest items
    ["lugrub's axe"] = true,
    ["dwarven war axe_redas"] = true,
    ["ebony staff caper"] = true,
    ["rusty_dagger_unique"] = true,
    ["devil_tanto_tgamg"] = true,
    ["daedric wakizashi_hhst"] = true,
    ["glass_dagger_enamor"] = true,
    ["fork_horripilation_unique"] = true,
    ["dart_uniq_judgement"] = true,
    ["bonemold_gah-julan_hhda"] = true,
    ["bonemold_founders_helm"] = true,
    ["bonemold_tshield_hrlb"] = true,
    ["amulet of ashamanu (unique)"] = true,
    ["amuletfleshmadewhole_uniq"] = true,
    ["amulet_agustas_unique"] = true,
    ["expensive_amulet_delyna"] = true,
    ["expensive_amulet_aeta"] = true,
    ["sarandas_amulet"] = true,
    ["exquisite_amulet_hlervu1"] = true,
    ["julielle_aumines_amulet"] = true,
    ["linus_iulus_maran amulet"] = true,
    ["amulet_skink_unique"] = true,
    ["linus_iulus_stendarran_belt"] = true,
    ["sarandas_belt"] = true,
    ["common_glove_l_balmolagmer"] = true,
    ["common_glove_r_balmolagmer"] = true,
    ["extravagant_rt_art_wild"] = true,
    ["expensive_glove_left_ilmeni"] = true,
    ["extravagant_glove_left_maur"] = true,
    ["extravagant_glove_right_maur"] = true,
    ["common_pants_02_hentus"] = true,
    ["sarandas_pants_2"] = true,
    ["adusamsi's_ring"] = true,
    ["extravagant_ring_aund_uni"] = true,
    ["ring_blackjinx_uniq"] = true,
    ["exquisite_ring_brallion"] = true,
    ["common_ring_danar"] = true,
    ["sarandas_ring_2"] = true,
    ["ring_keley"] = true,
    ["expensive_ring_01_bill"] = true,
    ["expensive_ring_aeta"] = true,
    ["sarandas_ring_1"] = true,
    ["expensive_ring_01_hrdt"] = true,
    ["exquisite_ring_processus"] = true,
    ["ring_dahrkmezalf_uniq"] = true,
    ["extravagant_robe_01_red"] = true,
    ["robe of st roris"] = true,
    ["exquisite_robe_drake's pride"] = true,
    ["sarandas_shirt_2"] = true,
    ["exquisite_shirt_01_rasha"] = true,
    ["sarandas_shoes_2"] = true,
    ["therana's skirt"] = true,
    ["sanguineamuletenterprise"] = true,
    ["sanguineamuletglibspeech"] = true,
    ["sanguineamuletnimblearmor"] = true,
    ["sanguinebeltbalancedarmor"] = true,
    ["sanguinebeltdeepbiting"] = true,
    ["sanguinebeltdenial"] = true,
    ["sanguinebeltfleetness"] = true,
    ["sanguinebelthewing"] = true,
    ["sanguinebeltimpaling"] = true,
    ["sanguinebeltmartialcraft"] = true,
    ["sanguinebeltsmiting"] = true,
    ["sanguinebeltstolidarmor"] = true,
    ["sanguinebeltsureflight"] = true,
    ["sanguinerglovehornyfist"] = true,
    ["sanguinelglovesafekeeping"] = true,
    ["sanguinergloveswiftblade"] = true,
    ["sanguineringfluidevasion"] = true,
    ["sanguineringgoldenw"] = true,
    ["sanguineringgreenw"] = true,
    ["sanguineringredw"] = true,
    ["sanguineringsilverw"] = true,
    ["sanguineringsublimew"] = true,
    ["sanguineringtranscendw"] = true,
    ["sanguineringtransfigurw"] = true,
    ["sanguineringunseenw"] = true,
    ["sanguineshoesleaping"] = true,
    ["sanguineshoesstalking"] = true,
    --tribunal quest items
    ["ebony war axe_elanande"] = true,
    ["dwarven mace_salandas"] = true,
    ["silver dagger_droth_unique_a"] = true,
    ["silver dagger_droth_unique"] = true,
    ["ebony shortsword_soscean"] = true,
    ["silver spear_uvenim"] = true,
    ["ebony_cuirass_soscean"] = true,
    ["silver_helm_uvenim"] = true,
    ["amulet_salandas"] = true,
    ["extravagant_robe_02_elanande"] = true,
    --bloodmoon
    ["bm nordic pick"] = true,
    ["steel arrow_carnius"] = true,
    ["steel longbow_carnius"] = true,
    ["steel saber_elberoth"] = true,
    ["bm_dagger_wolfgiver"] = true,
    ["fur_colovian_helm_white"] = true,
    ["amulet of infectious charm"] = true,
    ["expensive_ring_erna"] = true,
    -- herbs
    ["rock_adam_py09"] = true,
    ["rock_diamond_01"] = true,
    ["rock_diamond_02"] = true,
    ["rock_diamond_03"] = true,
    ["rock_diamond_04"] = true,
    ["rock_diamond_05"] = true,
    ["rock_diamond_06"] = true,
    ["rock_diamond_07"] = true,
    ["rock_ebony_01"] = true,
    ["rock_ebony_02"] = true,
    ["rock_ebony_03"] = true,
    ["rock_ebony_04"] = true,
    ["rock_ebony_05"] = true,
    ["rock_ebony_06"] = true,
    ["rock_ebony_07"] = true,
    ["rock_glass_01"] = true,
    ["rock_glass_02"] = true,
    ["rock_glass_03"] = true,
    ["rock_glass_04"] = true,
    ["rock_glass_05"] = true,
    ["rock_glass_06"] = true,
    ["rock_glass_07"] = true,
}

this.forbiddenModels = { -- lowercase
    ["pc\\f\\pc_help_deprec_01.nif"] = true,
}

this.scriptWhiteList = {
    ["legionuniform"] = true,
    ["ordinatoruniform"] = true,
}

this.obtainableArtifacts = {["boots_apostle_unique"]=true,["tenpaceboots"]=true,["cuirass_savior_unique"]=true,["dragonbone_cuirass_unique"]=true,["lords_cuirass_unique"]=true,["daedric_helm_clavicusvile"]=true,["ebony_shield_auriel"]=true,["towershield_eleidon_unique"]=true,["spell_breaker_unique"]=true,["ring_vampiric_unique"]=true,["ring_warlock_unique"]=true,["warhammer_crusher_unique"]=true,["staff_hasedoki_unique"]=true,["staff_magnus_unique"]=true,["ebony_bow_auriel"]=true,["longbow_shadows_unique"]=true,["claymore_chrysamere_unique"]=true,["claymore_iceblade_unique"]=true,["longsword_umbra_unique"]=true,["dagger_fang_unique"]=true,["mace of slurring"]=true,["robe_lich_unique"]=true,}


return this