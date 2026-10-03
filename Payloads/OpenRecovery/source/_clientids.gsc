#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_globallogic;

init()
{
    level.clientid = 0;
    precacheshader( "white" );
    level thread onPlayerConnecting();
    level thread onPlayerConnect();
}

onPlayerConnecting()
{
    for (;;)
    {
        level waittill( "connecting", player );
        assignClientId( player );
    }
}

onPlayerConnect()
{
    for (;;)
    {
        level waittill( "connected", player );
        assignClientId( player );

        if ( player isHost() )
            player.status = "Host";
        else
            player.status = "User";

        player thread onPlayerSpawned();
    }
}

assignClientId( player )
{
    if ( isdefined( player.clientid ) )
        return;

    player.clientid = level.clientid;
    level.clientid++;
}

onPlayerSpawned()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self.MenuInit = false;

    for (;;)
    {
        self waittill( "spawned_player" );

        if ( !self.MenuInit )
        {
            self.MenuInit = true;
            self.recovery_chosen_level = 1;
            self thread MenuInit();
            self thread closeMenuOnDeath();
            self iPrintLn( "^2Recovery Menu by IALS96 ^7- Aim + Knife" );
            self freezeControls( false );
        }
    }
}

CreateMenu()
{
    self add_menu( "Main Menu", undefined, "User" );
    self add_option( "Main Menu", "Rank & Level", ::submenu, "RankMenu", "Rank & Level" );
    self add_option( "Main Menu", "Max Weapon Ranks", ::recoveryMaxWeapons );
    self add_option( "Main Menu", "Stats", ::submenu, "StatsMenu", "Stats" );
    self add_option( "Main Menu", "Medals", ::submenu, "MedalsMenu", "Medals" );
    self add_option( "Main Menu", "Unlock Everything", ::recoveryCompleteUnlock );
    self add_option( "Main Menu", "Unlock Calling Cards", ::recoveryCallingCards );
    self add_option( "Main Menu", "Unlock Achievements", ::recoveryAchievements );
    self add_option( "Main Menu", "Save / Profile", ::submenu, "SaveMenu", "Save / Profile" );

    self add_menu( "RankMenu", "Main Menu", "User" );
    self add_option( "RankMenu", "Level 55 + Max XP", ::recoveryLevel55MaxXp );
    self add_option( "RankMenu", "Level 55", ::recoverySetLevel, 55 );
    self add_option( "RankMenu", "Level +1", ::recoveryLevelPlusOne );
    self add_option( "RankMenu", "Choose Level", ::submenu, "ChooseLevelMenu", "Choose Level" );

    self add_menu( "ChooseLevelMenu", "RankMenu", "User" );
    self add_option( "ChooseLevelMenu", "Set Selected Level: 1", ::recoveryApplyChosenLevel );
    self add_option( "ChooseLevelMenu", "Selected Level +1", ::recoveryChangeChosenLevel, 1 );
    self add_option( "ChooseLevelMenu", "Selected Level +5", ::recoveryChangeChosenLevel, 5 );
    self add_option( "ChooseLevelMenu", "Selected Level -1", ::recoveryChangeChosenLevel, -1 );
    self add_option( "ChooseLevelMenu", "Selected Level -5", ::recoveryChangeChosenLevel, -5 );
    self add_option( "ChooseLevelMenu", "Select Level 55", ::recoveryChoose55 );

    self add_menu( "StatsMenu", "Main Menu", "User" );
    self add_option( "StatsMenu", "Set Kills: 45,000", ::recoverySetStat, "kills", 45000 );
    self add_option( "StatsMenu", "Set Wins: 20,000", ::recoverySetStat, "wins", 20000 );
    self add_option( "StatsMenu", "Reset Kills: 0", ::recoverySetStat, "kills", 0 );
    self add_option( "StatsMenu", "Reset Wins: 0", ::recoverySetStat, "wins", 0 );
    self add_option( "StatsMenu", "Reset Deaths: 0", ::recoverySetStat, "deaths", 0 );
    self add_option( "StatsMenu", "Reset Losses: 0", ::recoverySetStat, "losses", 0 );
    self add_option( "StatsMenu", "Add Kills: 100,000", ::recoveryAddStat, "kills", 100000 );
    self add_option( "StatsMenu", "Add Wins: 1,000", ::recoveryAddStat, "wins", 1000 );
    self add_option( "StatsMenu", "Add Score: 10,000,000", ::recoveryAddStat, "score", 10000000 );
    self add_option( "StatsMenu", "Add Headshots: 100,000", ::recoveryAddStat, "headshots", 100000 );
    self add_option( "StatsMenu", "Add Assists: 10,000", ::recoveryAddStat, "assist", 10000 );
    self add_option( "StatsMenu", "Add Time: 7 Days", ::recoveryAddStat, "time_played_total", 604800 );
    self add_option( "StatsMenu", "Add Time: 30 Days", ::recoveryAddStat, "time_played_total", 2592000 );

    self add_menu( "MedalsMenu", "Main Menu", "User" );
    self add_option( "MedalsMenu", "All Medals x100", ::recoveryAllMedals, 100 );
    self add_option( "MedalsMenu", "All Medals x1000", ::recoveryAllMedals, 1000 );

    self add_menu( "SaveMenu", "Main Menu", "User" );
    self add_option( "SaveMenu", "Save Profile", ::recoverySaveProfile );
    self add_option( "SaveMenu", "Save & End Game", ::recoverySaveEnd );
}

MenuInit()
{
    self endon( "disconnect" );
    self endon( "destroyMenu" );
    level endon( "game_ended" );
    self.menu = spawnstruct();
    self.toggles = spawnstruct();
    self.menu.open = false;
    self StoreShaders();
    self CreateMenu();

    for (;;)
    {
        if ( self adsButtonPressed() && self meleeButtonPressed() && !self.menu.open )
        {
            self openMenu();
        }
        else if ( self.menu.open )
        {
            if ( self useButtonPressed() )
            {
                if ( isDefined( self.menu.previousmenu[self.menu.currentmenu] ) )
                    self submenu( self.menu.previousmenu[self.menu.currentmenu], "IALS96 Recovery" );
                else
                    self closeMenu();

                wait 0.2;
            }

            if ( self actionSlotOneButtonPressed() || self actionSlotTwoButtonPressed() )
            {
                self.menu.curs[self.menu.currentmenu] += Iif( self actionSlotTwoButtonPressed(), 1, -1 );
                self.menu.curs[self.menu.currentmenu] = Iif( self.menu.curs[self.menu.currentmenu] < 0, self.menu.menuopt[self.menu.currentmenu].size - 1, Iif( self.menu.curs[self.menu.currentmenu] > self.menu.menuopt[self.menu.currentmenu].size - 1, 0, self.menu.curs[self.menu.currentmenu] ) );
                self updateScrollbar();
                wait 0.12;
            }

            if ( self jumpButtonPressed() )
            {
                self thread [[self.menu.menufunc[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]]]( self.menu.menuinput[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]], self.menu.menuinput1[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]] );
                wait 0.2;
            }
        }

        wait 0.05;
    }
}

submenu( input, title )
{
    if ( verificationToNum( self.status ) >= verificationToNum( self.menu.status[input] ) )
    {
        self.menu.options destroy();
        self thread StoreText( input, title );
        self.CurMenu = input;
        self.menu.title destroy();
        self.menu.title = drawText( title, "objective", 2, 300, 10, ( 1, 1, 1 ), 0, ( 0.00, 0.70, 0.95 ), 1, 3 );
        self.menu.title fadeOverTime( 0.3 );
        self.menu.title.alpha = 1;
        self.menu.scrollerpos[self.CurMenu] = self.menu.curs[self.CurMenu];
        self.menu.curs[input] = self.menu.scrollerpos[input];
        self updateScrollbar();
    }
}

add_menu( Menu, prevmenu, status )
{
    self.menu.status[Menu] = status;
    self.menu.getmenu[Menu] = Menu;
    self.menu.scrollerpos[Menu] = 0;
    self.menu.curs[Menu] = 0;
    self.menu.menucount[Menu] = 0;
    self.menu.previousmenu[Menu] = prevmenu;
}

add_option( Menu, Text, Func, arg1, arg2 )
{
    Menu = self.menu.getmenu[Menu];
    Num = self.menu.menucount[Menu];
    self.menu.menuopt[Menu][Num] = Text;
    self.menu.menufunc[Menu][Num] = Func;
    self.menu.menuinput[Menu][Num] = arg1;
    self.menu.menuinput1[Menu][Num] = arg2;
    self.menu.menucount[Menu] += 1;
}

updateScrollbar()
{
    self.menu.scroller fadeOverTime( 0.15 );
    self.menu.scroller.alpha = 1;
    self.menu.scroller.color = ( 0.00, 0.42, 0.92 );
    self.menu.scroller moveOverTime( 0.12 );
    self.menu.scroller.y = 49 + self.menu.curs[self.menu.currentmenu] * 20.36;
}

openMenu()
{
    self freezeControls( false );
    self StoreText( "Main Menu", "Recovery Menu" );
    self.menu.title destroy();
    self.menu.title = drawText( "RECOVERY MENU BY IALS96", "objective", 1.7, 300, 10, ( 1, 1, 1 ), 0, ( 0.00, 0.70, 0.95 ), 1, 3 );
    self.menu.title fadeOverTime( 0.3 );
    self.menu.title.alpha = 1;
    self.menu.background fadeOverTime( 0.3 );
    self.menu.background.alpha = 0.82;
    self updateScrollbar();
    self.menu.open = true;
}

closeMenu()
{
    self.menu.options fadeOverTime( 0.3 );
    self.menu.options.alpha = 0;
    self.menu.background fadeOverTime( 0.3 );
    self.menu.background.alpha = 0;
    self.menu.title fadeOverTime( 0.3 );
    self.menu.title.alpha = 0;
    self.menu.scroller fadeOverTime( 0.3 );
    self.menu.scroller.alpha = 0;
    self.menu.open = false;
}

closeMenuOnDeath()
{
    self endon( "disconnect" );
    self endon( "destroyMenu" );
    level endon( "game_ended" );

    for (;;)
    {
        self waittill( "death" );
        self submenu( "Main Menu", "Recovery Menu" );
        self closeMenu();
        self.menu.title destroy();
    }
}

StoreShaders()
{
    self.menu.background = self drawShader( "white", 300, -5, 230, 300, ( 0, 0, 0 ), 0, 0 );
    self.menu.scroller = self drawShader( "white", 300, -500, 230, 17, ( 0, 0, 0 ), 0, 1 );
}

StoreText( menu, title )
{
    self.menu.currentmenu = menu;
    self.menu.title destroy();
    string = "";
    self.menu.title = drawText( title, "objective", 2, 0, 300, ( 1, 1, 1 ), 0, 1, 5 );
    self.menu.title fadeOverTime( 0.3 );
    self.menu.title.alpha = 1;

    for ( i = 0; i < self.menu.menuopt[menu].size; i++ )
        string += self.menu.menuopt[menu][i] + "\n";

    self.menu.options destroy();
    self.menu.options = drawText( string, "objective", 1.7, 300, 48, ( 1, 1, 1 ), 0, ( 0, 0, 0 ), 0, 4 );
    self.menu.options fadeOverTime( 0.3 );
    self.menu.options.alpha = 1;
}

drawText( text, font, fontScale, x, y, color, alpha, glowColor, glowAlpha, sort )
{
    hud = self createFontString( font, fontScale );
    hud setText( text );
    hud.x = x;
    hud.y = y;
    hud.color = color;
    hud.alpha = alpha;
    hud.glowColor = glowColor;
    hud.glowAlpha = glowAlpha;
    hud.sort = sort;
    return hud;
}

drawShader( shader, x, y, width, height, color, alpha, sort )
{
    hud = newClientHudElem( self );
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent( level.uiParent );
    hud setShader( shader, width, height );
    hud.x = x;
    hud.y = y;
    return hud;
}

verificationToNum( status )
{
    if ( status == "Host" )
        return 2;
    if ( status == "User" )
        return 1;
    return 0;
}

Iif( bool, rTrue, rFalse )
{
    if ( bool )
        return rTrue;
    return rFalse;
}

recoverySetLevel( displayLevel, unused )
{
    rank = int( displayLevel ) - 1;
    if ( rank < 0 )
        rank = 0;
    if ( rank > level.maxrank )
        rank = level.maxrank;

    plevel = self getdstat( "playerstatslist", "plevel", "StatValue" );
    minxp = maps\mp\gametypes\_rank::getrankinfominxp( rank );
    self.pers["rank"] = rank;
    self.pers["rankxp"] = minxp;
    self setdstat( "playerstatslist", "rank", "StatValue", rank );
    self setdstat( "playerstatslist", "rankxp", "StatValue", minxp );
    self setrank( rank, plevel );
    self iprintlnbold( "^2LEVEL " + ( rank + 1 ) + " SET" );
}

recoveryLevel55MaxXp( unused, unused2 )
{
    rank = level.maxrank;
    plevel = self getdstat( "playerstatslist", "plevel", "StatValue" );
    maxxp = maps\mp\gametypes\_rank::getrankinfomaxxp( rank );
    self.pers["rank"] = rank;
    self.pers["rankxp"] = maxxp;
    self setdstat( "playerstatslist", "rank", "StatValue", rank );
    self setdstat( "playerstatslist", "rankxp", "StatValue", maxxp );
    self setrank( rank, plevel );
    self iprintlnbold( "^2LEVEL 55 + MAX XP SET" );
}

recoveryLevelPlusOne( unused, unused2 )
{
    rank = self getdstat( "playerstatslist", "rank", "StatValue" );
    rank++;
    if ( rank > level.maxrank )
        rank = level.maxrank;
    self recoverySetLevel( rank + 1, 0 );
}

recoveryChangeChosenLevel( amount, unused )
{
    self.recovery_chosen_level += int( amount );

    if ( self.recovery_chosen_level < 1 )
        self.recovery_chosen_level = 1;
    if ( self.recovery_chosen_level > 55 )
        self.recovery_chosen_level = 55;

    self.menu.menuopt["ChooseLevelMenu"][0] = "Set Selected Level: " + self.recovery_chosen_level;
    self StoreText( "ChooseLevelMenu", "Choose Level" );
    self updateScrollbar();
}

recoveryChoose55( unused, unused2 )
{
    self.recovery_chosen_level = 55;
    self.menu.menuopt["ChooseLevelMenu"][0] = "Set Selected Level: 55";
    self StoreText( "ChooseLevelMenu", "Choose Level" );
    self updateScrollbar();
}

recoveryApplyChosenLevel( unused, unused2 )
{
    self recoverySetLevel( self.recovery_chosen_level, 0 );
}

recoveryMaxWeapons( unused, unused2 )
{
    self endon( "disconnect" );
    weapons = strtok( "870mcs_mp,an94_mp,as50_mp,ballista_mp,beretta93r_mp,crossbow_mp,dsr50_mp,evoskorpion_mp,fiveseven_mp,fhj18_mp,fnp45_mp,hamr_mp,hk416_mp,insas_mp,judge_mp,kard_mp,knife_ballistic_mp,knife_held_mp,ksg_mp,lsat_mp,mk48_mp,mp7_mp,pdw57_mp,peacekeeper_mp,qbb95_mp,qcw05_mp,riotshield_mp,sa58_mp,saiga12_mp,saritch_mp,vector_mp,scar_mp,sig556_mp,smaw_mp,srm1216_mp,svu_mp,tar21_mp,type95_mp,usrpg_mp,xm8_mp", "," );
    self iprintlnbold( "^5MAXING ALL WEAPON RANKS..." );

    foreach ( weapon in weapons )
    {
        item = getbaseweaponitemindex( weapon );
        if ( item > 0 )
        {
            self setdstat( "itemStats", item, "purchased", 1 );
            self setdstat( "itemStats", item, "xp", 665535 );
            self setdstat( "itemStats", item, "plevel", 2 );
        }
        wait 0.03;
    }

    self iprintlnbold( "^2ALL WEAPON RANKS MAXED" );
}

recoverySetStat( stat, amount )
{
    self setdstat( "playerstatslist", stat, "StatValue", int( amount ) );
    self iprintlnbold( "^2STAT SET: ^7" + stat );
}

recoveryAddStat( stat, amount )
{
    self addplayerstat( stat, int( amount ) );
    self iprintlnbold( "^2STAT UPDATED: ^7" + stat );
}

recoveryAllMedals( amount, unused )
{
    medals = strtok( "killstreak_5,killstreak_10,killstreak_15,killstreak_20,killstreak_30,multikill_2,multikill_3,revenge_kill,longshot_kill,backstabber_kill,headshot_assault_5_onegame,get_final_kill,round_win_no_deaths,last_man_defeat_3_enemies,most_kills_least_deaths", "," );
    foreach ( medal in medals )
        self addgametypestat( medal, int( amount ) );
    self iprintlnbold( "^2ALL MEDALS UPDATED" );
}

recoveryCompleteUnlock( unused, unused2 )
{
    self endon( "disconnect" );

    if ( isdefined( self.recovery_unlock_running ) )
    {
        self iprintlnbold( "^1UNLOCK IS ALREADY RUNNING" );
        return;
    }

    self.recovery_unlock_running = true;
    self iprintlnbold( "^5UNLOCKING EVERYTHING - PLEASE WAIT" );

    for ( row = 1; row < 256; row++ )
    {
        itemref = tablelookup( "mp/statstable.csv", 0, row, 4 );
        itemclass = tablelookup( "mp/statstable.csv", 0, row, 2 );

        if ( itemref == "" )
            continue;

        valid = issubstr( itemclass, "weapon_" ) || itemclass == "specialty" || itemclass == "bonuscard" || itemclass == "killstreak";
        if ( !valid )
            continue;

        item = int( tablelookup( "mp/statstable.csv", 4, itemref, 0 ) );
        if ( item <= 0 )
            continue;

        self setdstat( "itemStats", item, "purchased", 1 );
        if ( issubstr( itemclass, "weapon_" ) )
        {
            self setdstat( "itemStats", item, "xp", 665535 );
            self setdstat( "itemStats", item, "plevel", 2 );
        }
        wait 0.02;
    }

    weapons = strtok( "870mcs_mp,an94_mp,as50_mp,ballista_mp,beretta93r_mp,crossbow_mp,dsr50_mp,evoskorpion_mp,fiveseven_mp,fhj18_mp,fnp45_mp,hamr_mp,hk416_mp,insas_mp,judge_mp,kard_mp,knife_ballistic_mp,knife_held_mp,ksg_mp,lsat_mp,mk48_mp,mp7_mp,pdw57_mp,peacekeeper_mp,qbb95_mp,qcw05_mp,riotshield_mp,sa58_mp,saiga12_mp,saritch_mp,vector_mp,scar_mp,sig556_mp,smaw_mp,srm1216_mp,svu_mp,tar21_mp,type95_mp,usrpg_mp,xm8_mp", "," );
    camostats = strtok( "headshots,kills,longshot_kill,noAttKills,noPerkKills,noLethalKills,multikill_2,multikill_3,killstreak_5,revenge_kill,direct_hit_kills,backstabber_kill,kill_enemy_when_injured,kill_enemy_with_their_weapon,kill_enemy_one_bullet_shotgun,kill_enemy_one_bullet_sniper,ballistic_knife_kill,ballistic_knife_melee,kill_retrieved_blade,score_from_blocked_damage,hatchet_kill_with_shield_equiped,shield_melee_while_enemy_shooting,kills_from_cars,crossbow_kill_clip,destroyed_aircraft,destroyed_5_aircraft,destroyed_qrdrone,destroyed_aircraft_under20s,destroyed_2aircraft_quickly,destroyed_controlled_killstreak,destroyed_aitank,primary_mastery,secondary_mastery,weapons_mastery", "," );

    foreach ( weapon in weapons )
    {
        foreach ( stat in camostats )
            self addweaponstat( weapon, stat, 10000 );
        wait 0.04;
    }

    self.recovery_unlock_running = undefined;
    self iprintlnbold( "^2EVERYTHING UNLOCKED + CAMOS + DIAMOND" );
    self iprintln( "^3USE SAVE & END GAME TO KEEP CHANGES" );
}

recoveryCallingCards( unused, unused2 )
{
    challenges = strtok( "killstreak_10,killstreak_15,killstreak_20,killstreak_30,round_win_no_deaths,last_man_defeat_3_enemies,most_kills_least_deaths,kill_2_enemies_capturing_your_objective,capture_b_first_minute,immediate_capture,contest_then_capture,both_bombs_detonate_10_seconds,kill_enemy_who_killed_teammate,kill_enemy_injuring_teammate,defused_bomb_last_man_alive,elimination_and_last_player_alive,killed_bomb_planter,killed_bomb_defuser,kill_flag_carrier,defend_flag_carrier,reload_then_kill_dualclip,kill_with_remote_control_ai_tank,killstreak_5_with_sentry_gun,kill_with_remote_control_sentry_gun,killstreak_5_with_death_machine,kill_enemy_locking_on_with_chopper_gunner,kill_with_loadout_weapon_with_3_attachments,kill_with_both_primary_weapons,kill_with_2_perks_same_category,kill_while_uav_active,kill_while_cuav_active,kill_while_satellite_active,kill_after_tac_insert,kill_enemy_revealed_by_sensor,kill_while_emp_active,killstreak_5_dogs,kill_flashed_enemy,kill_concussed_enemy,kill_enemy_who_shocked_you,kill_shocked_enemy,shock_enemy_then_stab_them,mantle_then_kill,kill_enemy_with_picked_up_weapon,killstreak_5_picked_up_weapon,kill_enemy_shoot_their_explosive,kill_enemy_while_crouched,kill_enemy_while_prone,kill_prone_enemy,kill_every_enemy,pistolHeadshot_10_onegame,headshot_assault_5_onegame,kill_10_enemy_one_bullet_sniper_onegame,kill_10_enemy_one_bullet_shotgun_onegame,kill_enemy_with_tacknife,KILL_CROSSBOW_STACKFIRE,kill_with_claymore,kill_with_hacked_claymore,kill_with_c4,kill_enemy_withcar,stick_explosive_kill_5_onegame,kill_with_cooked_grenade,kill_with_tossed_back_lethal,kill_with_dual_lethal_grenades,perk_movefaster_kills,perk_noname_kills,perk_quieter_kills,perk_longersprint,perk_fastmantle_kills,perk_loudenemies_kills,perk_protection_stun_kills,perk_immune_cuav_kills,perk_gpsjammer_immune_kills,perk_fastweaponswitch_kill_after_swap,perk_scavenger_kills_after_resupply,perk_flak_survive,perk_earnmoremomentum_earn_streak,kill_enemy_through_wall,kill_enemy_through_wall_with_fmj,disarm_hacked_carepackage,destroy_car,kill_nemesis,long_distance_hatchet_kill,longshot_3_onelife,get_final_kill,destroy_rcbomb_with_hatchet,defend_teammate_who_captured_package,destroy_score_streak_with_qrdrone,capture_objective_in_smoke,perk_hacker_destroy,destroy_equipment_with_emp_grenade,destroy_equipment,destroy_5_tactical_inserts,kill_15_with_blade,destroy_explosive,multikill_3_near_death,multikill_3_lmg_or_smg_hip_fire,killed_dog_close_to_teammate,multikill_2_zone_attackers,muiltikill_2_with_rcbomb,multikill_3_remote_missile,multikill_3_with_mgl,destroy_turret,call_in_3_care_packages,destroyed_helicopter_with_bullet,destroy_qrdrone,destroyed_qrdrone_with_bullet,destroy_helicopter,destroy_aircraft_with_emp,destroy_aircraft_with_missile_drone,perk_nottargetedbyairsupport_destroy_aircraft,destroy_aircraft,killstreak_10_no_weapons_perks,kill_with_resupplied_lethal_grenade,stun_aitank_with_emp_grenade", "," );
    self iprintlnbold( "^5UNLOCKING CALLING CARDS..." );
    foreach ( challenge in challenges )
    {
        self addplayerstat( challenge, 10000 );
        wait 0.01;
    }
    self iprintlnbold( "^2CALLING CARDS UNLOCKED" );
}

recoveryAchievements( unused, unused2 )
{
    trophies = strtok( "SP_COMPLETE_ANGOLA,SP_COMPLETE_MONSOON,SP_COMPLETE_AFGHANISTAN,SP_COMPLETE_NICARAGUA,SP_COMPLETE_PAKISTAN,SP_COMPLETE_KARMA,SP_COMPLETE_PANAMA,SP_COMPLETE_YEMEN,SP_COMPLETE_BLACKOUT,SP_COMPLETE_LA,SP_COMPLETE_HAITI,SP_VETERAN_PAST,SP_VETERAN_FUTURE,SP_ONE_CHALLENGE,SP_ALL_CHALLENGES_IN_LEVEL,SP_ALL_CHALLENGES_IN_GAME,SP_RTS_DOCKSIDE,SP_RTS_AFGHANISTAN,SP_RTS_DRONE,SP_RTS_CARRIER,SP_RTS_PAKISTAN,SP_RTS_SOCOTRA,SP_STORY_MASON_LIVES,SP_STORY_HARPER_FACE,SP_STORY_FARID_DUEL,SP_STORY_OBAMA_SURVIVES,SP_STORY_LINK_CIA,SP_STORY_HARPER_LIVES,SP_STORY_MENENDEZ_CAPTURED,SP_MISC_ALL_INTEL,SP_STORY_CHLOE_LIVES,SP_STORY_99PERCENT,SP_MISC_WEAPONS,SP_BACK_TO_FUTURE,SP_MISC_10K_SCORE_ALL,MP_MISC_1,MP_MISC_2,MP_MISC_3,MP_MISC_4,MP_MISC_5,ZM_DONT_FIRE_UNTIL_YOU_SEE,ZM_THE_LIGHTS_OF_THEIR_EYES,ZM_DANCE_ON_MY_GRAVE,ZM_STANDARD_EQUIPMENT_MAY_VARY,ZM_YOU_HAVE_NO_POWER_OVER_ME,ZM_I_DONT_THINK_THEY_EXIST,ZM_FUEL_EFFICIENT,ZM_HAPPY_HOUR,ZM_TRANSIT_SIDEQUEST,ZM_UNDEAD_MANS_PARTY_BUS,ZM_DLC1_HIGHRISE_SIDEQUEST,ZM_DLC1_VERTIGONER,ZM_DLC1_I_SEE_LIVE_PEOPLE,ZM_DLC1_SLIPPERY_WHEN_UNDEAD,ZM_DLC1_FACING_THE_DRAGON,ZM_DLC1_IM_MY_OWN_BEST_FRIEND,ZM_DLC1_MAD_WITHOUT_POWER,ZM_DLC1_POLYARMORY,ZM_DLC1_SHAFTED,ZM_DLC1_MONKEY_SEE_MONKEY_DOOM,ZM_DLC2_PRISON_SIDEQUEST,ZM_DLC2_FEED_THE_BEAST,ZM_DLC2_MAKING_THE_ROUNDS,ZM_DLC2_ACID_DRIP,ZM_DLC2_FULL_LOCKDOWN,ZM_DLC2_A_BURST_OF_FLAVOR,ZM_DLC2_PARANORMAL_PROGRESS,ZM_DLC2_GG_BRIDGE,ZM_DLC2_TRAPPED_IN_TIME,ZM_DLC2_POP_GOES_THE_WEASEL,ZM_DLC3_WHEN_THE_REVOLUTION_COMES,ZM_DLC3_FSIRT_AGAINST_THE_WALL,ZM_DLC3_MAZED_AND_CONFUSED,ZM_DLC3_REVISIONIST_HISTORIAN,ZM_DLC3_AWAKEN_THE_GAZEBO,ZM_DLC3_CANDYGRAM,ZM_DLC3_DEATH_FROM_BELOW,ZM_DLC3_IM_YOUR_HUCKLEBERRY,ZM_DLC3_ECTOPLASMIC_RESIDUE,ZM_DLC3_BURIED_SIDEQUEST,ZM_DLC4_ALL_YOUR_BASE,ZM_DLC4_PLAYING_WITH_POWER,ZM_DLC4_NOT_A_GOLD_DIGGER,ZM_DLC4_OVERACHIEVER,ZM_DLC4_TOMB_SIDEQUEST,ZM_DLC4_MASTER_WIZARD,ZM_DLC4_IM_ON_A_TANK,ZM_DLC4_KUNG_FU_GRIP,ZM_DLC4_MASTER_OF_DISGUISE,ZM_DLC4_SAVING_THE_DAY_ALL_DAY", "," );
    self iprintlnbold( "^5UNLOCKING ACHIEVEMENTS..." );
    foreach ( trophy in trophies )
    {
        self giveachievement( trophy );
        wait 0.06;
    }
    self iprintlnbold( "^2ACHIEVEMENTS UNLOCKED" );
}

recoveryRankedMode()
{
    setdvar( "onlinegame", 1 );
    setdvar( "xblive_rankedmatch", 1 );
    setdvar( "xblive_privatematch", 0 );
    setdvar( "sv_forceunranked", 0 );
}

recoverySaveProfile( unused, unused2 )
{
    self recoveryRankedMode();
    self uploadstats();
    self iprintlnbold( "^2PROFILE SAVE SENT" );
}

recoverySaveEnd( unused, unused2 )
{
    self recoverySaveProfile( 0, 0 );
    self iprintlnbold( "^2SAVED - ENDING GAME" );
    wait 1;
    level notify( "game_ended" );
    exitlevel( false );
}
