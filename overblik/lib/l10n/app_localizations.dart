import 'dart:async';

import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get _en => locale.languageCode == 'en';

  String _t(String da, String en) => _en ? en : da;

  // ── Common ────────────────────────────────────────────────────────────────

  String get cancel => _t('Annuller', 'Cancel');
  String get save => _t('Gem', 'Save');
  String get add => _t('Tilføj', 'Add');
  String get remove => _t('Fjern', 'Remove');
  String get delete => _t('Slet', 'Delete');
  String get close => _t('Luk', 'Close');
  String get back => _t('Tilbage', 'Back');
  String get create => _t('Opret', 'Create');
  String get approve => _t('Godkend', 'Approve');
  String get reject => _t('Afvis', 'Reject');
  String get retry => _t('Prøv igen', 'Try again');
  String get yes => _t('Ja', 'Yes');
  String get no => _t('Nej', 'No');
  String get logout => _t('Log ud', 'Log out');
  String get child => _t('Barn', 'Child');
  String get parent => _t('Forælder', 'Parent');
  String get family => _t('Familie', 'Family');
  String get all => _t('Alle', 'All');
  String get name => _t('Navn', 'Name');
  String get title => _t('Titel', 'Title');
  String get emoji => _t('Emoji', 'Emoji');
  String get description => _t('Beskrivelse', 'Description');
  String get reload => _t('Genindlæs', 'Reload');
  String get changesSaved => _t('Din ændring er gemt.', 'Your change has been saved.');

  // ── Login Screen ──────────────────────────────────────────────────────────

  String get loginParentSectionTitle => _t('Forælder', 'Parent');
  String get loginParentSubtitle => _t('Log ind, hvis du allerede har adgang.', 'Log in if you already have access.');
  String get emailLabel => _t('Email', 'Email');
  String get passwordLabel => _t('Adgangskode', 'Password');
  String get loginButton => _t('Log ind', 'Log in');
  String get emailRequired => _t('Skriv din email', 'Enter your email');
  String get emailInvalid => _t('Skriv en gyldig email', 'Enter a valid email');
  String get passwordRequired => _t('Skriv din adgangskode', 'Enter your password');
  String get passwordTooShort => _t('Mindst 6 tegn', 'At least 6 characters');
  String get childLoginCardTitle => _t('Barn', 'Child');
  String get childLoginCardSubtitle => _t('Log ind med familiekode og børnekode.', 'Log in with family code and child code.');
  String get newParentCardTitle => _t('Ny forælder?', 'New parent?');
  String get newParentCardSubtitle => _t('Opret en ny familie eller anmod om adgang til en eksisterende familie.', 'Create a new family or request access to an existing family.');
  String get familyTagline => _t('Et roligt overblik for hele familien', 'A calm overview for the whole family');
  String get mom => _t('Mor', 'Mom');
  String get dad => _t('Far', 'Dad');
  String loginError(Object e) => _t('Noget gik galt under login: $e', 'Something went wrong during login: $e');

  // ── Settings Screen ───────────────────────────────────────────────────────

  String get settingsTitle => _t('Indstillinger', 'Settings');
  String get notificationsSectionTitle => _t('Notifikationer', 'Notifications');
  String get notificationsForNewActivities => _t('Notifikationer til nye aktiviteter', 'Notifications for new activities');
  String get notificationsNewActivitiesSubtitle => _t('Standardindstilling for nye aktiviteter. Kan ændres per aktivitet.', 'Default setting for new activities. Can be changed per activity.');
  String get defaultReminderTime => _t('Standard påmindelsestid', 'Default reminder time');
  String get defaultNotifStyle => _t('Standard notifikationsstil', 'Default notification style');
  String get appearanceSectionTitle => _t('Udseende', 'Appearance');
  String get themeLabel => _t('Tema', 'Theme');
  String get colorLabel => _t('Farve', 'Color');
  String get lightMode => _t('Lys tilstand', 'Light mode');
  String get darkMode => _t('Mørk tilstand', 'Dark mode');
  String get colorGreen => _t('Grøn', 'Green');
  String get colorBlue => _t('Blå', 'Blue');
  String get colorPurple => _t('Lilla', 'Purple');
  String get colorOrange => _t('Orange', 'Orange');
  String get colorPink => _t('Rosa', 'Pink');
  String get languageSectionTitle => _t('Sprog', 'Language');
  String get languageLabel => _t('Sprog', 'Language');
  String get languageDanish => _t('Dansk', 'Danish');
  String get languageEnglish => _t('Engelsk', 'English');
  String get familyProfilesSectionTitle => _t('Familieprofiler', 'Family profiles');
  String get manageProfilesInfoTitle => _t('Administrér profiler', 'Manage profiles');
  String get manageProfilesInfoText => _t(
    'Opret børneprofiler, vælg adgangsniveau, se login-koder og ændre børnenes rolle mellem begrænset og udvidet adgang.',
    'Create child profiles, choose access level, view login codes and change children\'s role between limited and extended access.',
  );
  String get manageProfilesButton => _t('Administrér profiler', 'Manage profiles');
  String get accessStructureSectionTitle => _t('Adgangsstruktur', 'Access structure');
  String get accessStructureParentTitle => _t('Forælder', 'Parent');
  String get accessStructureParentText => _t(
    'Har fuld adgang til at oprette, redigere og slette aktiviteter samt administrere profiler, belønninger og indstillinger.',
    'Has full access to create, edit and delete activities as well as manage profiles, rewards and settings.',
  );
  String get accessStructureChildLimitedTitle => _t('Barn · begrænset adgang', 'Child · limited access');
  String get accessStructureChildLimitedText => _t(
    'Kan se kalenderen, markere aktiviteter som udført og krydse checklisten af.',
    'Can view the calendar, mark activities as completed and check off the checklist.',
  );
  String get accessStructureChildExtendedTitle => _t('Barn · udvidet adgang', 'Child · extended access');
  String get accessStructureChildExtendedText => _t(
    'Kan også oprette, redigere og slette egne aktiviteter.',
    'Can also create, edit and delete own activities.',
  );

  // ── Notification Preference Labels ────────────────────────────────────────

  String reminderLabel(int minutes) {
    if (minutes == 60) return _t('1 time før', '1 hour before');
    return _t('$minutes minutter før', '$minutes minutes before');
  }

  String notificationStyleLabel(String style) {
    switch (style) {
      case 'tydelig': return _t('Tydelig', 'Clear');
      case 'rolig':   return _t('Rolig', 'Calm');
      case 'diskret': return _t('Diskret', 'Discreet');
      default:        return _t('Tydelig', 'Clear');
    }
  }

  String notificationStyleDescription(String style) {
    switch (style) {
      case 'tydelig': return _t('Lyd og vibration – let at lægge mærke til', 'Sound and vibration – easy to notice');
      case 'rolig':   return _t('Vibration, ingen lyd – mindre forstyrrende', 'Vibration, no sound – less disruptive');
      case 'diskret': return _t('Ingen lyd, ingen vibration – stille påmindelser', 'No sound, no vibration – silent reminders');
      default:        return _t('Lyd og vibration – let at lægge mærke til', 'Sound and vibration – easy to notice');
    }
  }

  // ── Profile Screen ────────────────────────────────────────────────────────

  String get profileTitle => _t('Profil', 'Profile');
  String get roleParentLabel => _t('Forælder', 'Parent');
  String get roleChildExtendedLabel => _t('Barn · udvidet adgang', 'Child · extended access');
  String get roleChildLimitedLabel => _t('Barn · begrænset adgang', 'Child · limited access');
  String get quickActions => _t('Hurtige handlinger', 'Quick actions');
  String get rewardsLabel => _t('Belønninger', 'Rewards');
  String get settingsLabel => _t('Indstillinger', 'Settings');
  String get familyAndParticipants => _t('Familie og deltagere', 'Family and participants');
  String get logoutDialogTitle => _t('Log ud', 'Log out');
  String get logoutDialogContent => _t('Er du sikker på, at du vil logge ud?', 'Are you sure you want to log out?');

  // ── Child Login Screen ────────────────────────────────────────────────────

  String get childLoginTitle => _t('Log ind som barn', 'Log in as child');
  String get childLoginSubtitle => _t('Indtast familiekode og børnekode', 'Enter family code and child code');
  String get familyCodeLabel => _t('Familiekode', 'Family code');
  String get familyCodeHint => _t('Indtast familiekoden', 'Enter the family code');
  String get familyCodeRequired => _t('Skriv familiekoden', 'Enter the family code');
  String get familyCodeTooShort => _t('Familiekoden er for kort', 'The family code is too short');
  String get childCodeLabel => _t('Børnekode', 'Child code');
  String get childCodeHint => _t('Indtast børnekoden', 'Enter the child code');
  String get childCodeRequired => _t('Skriv børnekoden', 'Enter the child code');
  String get childCodeTooShort => _t('Børnekoden er for kort', 'The child code is too short');
  String get continueButton => _t('Fortsæt', 'Continue');
  String childLoginAuthError(String message) => _t('Loginfejl: $message', 'Login error: $message');
  String get childLoginFailed => _t('Kunne ikke logge barnet ind. Prøv igen.', 'Could not log in child. Please try again.');
  String get wrongCodes => _t('Familiekoden eller børnekoden er forkert.', 'The family code or child code is incorrect.');
  String get noSessionCreated => _t('Børnelogin lykkedes, men der blev ikke oprettet en aktiv session.', 'Child login succeeded, but no active session was created.');

  // ── View Switcher / Action Row ────────────────────────────────────────────

  String get viewDay => _t('Dag', 'Day');
  String get viewWeek => _t('Uge', 'Week');
  String get viewMonth => _t('Måned', 'Month');
  String get todayLabel => _t('I dag', 'Today');
  String get newActivityButton => _t('Ny aktivitet', 'New activity');

  // ── Create Family Screen ──────────────────────────────────────────────────

  String get createFamilyTitle => _t('Opret familie', 'Create family');
  String get createFamilySubtitle => _t('Start med den første forælder', 'Start with the first parent');
  String get parentNameLabel => _t('Forælders navn', 'Parent name');
  String get familyNameLabel => _t('Familienavn', 'Family name');
  String get confirmPasswordLabel => _t('Gentag adgangskode', 'Confirm password');
  String get parentNameRequired => _t('Skriv navn', 'Enter name');
  String get familyNameRequired => _t('Skriv familienavn', 'Enter family name');
  String get confirmPasswordRequired => _t('Gentag adgangskoden', 'Confirm password');
  String get passwordsDoNotMatch => _t('Adgangskoderne matcher ikke', 'Passwords do not match');
  String familyCreatedWelcome(String n) => _t('Familien er oprettet. Velkommen, $n!', 'Family created. Welcome, $n!');

  // ── Request Parent Join Screen ────────────────────────────────────────────

  String get sendRequestButton => _t('Send anmodning', 'Send request');
  String get parentNameTooShort => _t('Navnet er for kort', 'Name is too short');
  String get accountNeedsEmailConfirm => _t(
    'Kontoen blev oprettet, men du skal muligvis bekræfte din email og logge ind, før anmodningen kan sendes.',
    'Account created, but you may need to confirm your email and log in before the request can be sent.',
  );

  // ── Activity Card / Detail Screen ────────────────────────────────────────

  String get markAsDone => _t('Marker som færdig', 'Mark as done');
  String get markAsNotDone => _t('Marker som ikke færdig', 'Mark as not done');
  String get deleteActivity => _t('Slet aktivitet', 'Delete activity');
  String deleteActivityConfirm(String title) => _t('Vil du slette "$title"?', 'Delete "$title"?');
  String get markAsDoneButton => _t('Markér udført', 'Mark as done');
  String get markedAsDoneButton => _t('Udført', 'Done');
  String get editLabel => _t('Rediger', 'Edit');
  String get cannotDeleteActivityPermission => _t('Du har ikke adgang til at slette denne aktivitet.', 'You do not have permission to delete this activity.');
  String get cannotUpdateActivityError => _t('Kunne ikke opdatere aktiviteten.', 'Could not update the activity.');
  String get cannotDeleteActivityError => _t('Kunne ikke slette aktiviteten.', 'Could not delete the activity.');

  // ── Filter Panel ──────────────────────────────────────────────────────────

  String get filterTitle => _t('Filter', 'Filter');
  String get myActivities => _t('Mine aktiviteter', 'My activities');
  String withProfile(String name) => _t('Med $name', 'With $name');
  String get familyAndOthers => _t('Familie / andre', 'Family / others');
  String get clearFilter => _t('Ryd', 'Clear');
  String get showAllFilter => _t('Vis alle', 'Show all');
  String get applyFilter => _t('Anvend filter', 'Apply filter');

  // ── Reward Card ───────────────────────────────────────────────────────────

  String belongsToProfile(String name) => _t('Tilhører: $name', 'Belongs to: $name');
  String get noProfileSelectedLabel => _t('Ingen profil valgt', 'No profile selected');
  String get deleteRewardTooltip => _t('Slet belønning', 'Delete reward');
  String get completedRewardsTitle => _t('Færdige belønninger', 'Completed rewards');
  String get inProgressRewardsTitle => _t('I gang', 'In progress');
  String get rewardEarnedTitle => _t('Belønning optjent!', 'Reward earned!');
  String get codeCopied => _t('Kode kopieret!', 'Code copied!');

  // ── Activity Detail Screen ────────────────────────────────────────────────

  String get noDescription => _t('Ingen beskrivelse', 'No description');
  String get unknownParticipant => _t('Ukendt deltager', 'Unknown participant');
  String get familyActivityNoParticipants => _t('Familieaktivitet (ingen specifikke deltagere)', 'Family activity (no specific participants)');
  String get wholeFamily => _t('Hele familien', 'The whole family');
  String get noSpecificParticipants => _t('Ingen specifikke deltagere', 'No specific participants');
  String get repeatsEveryDay => _t('Gentages hver dag', 'Repeats every day');
  String repeatsEveryNDays(int n) => _t('Gentages hver $n. dag', 'Repeats every $n days');
  String get repeatsEveryWeek => _t('Gentages hver uge', 'Repeats every week');
  String repeatsEveryNWeeks(int n) => _t('Gentages hver $n. uge', 'Repeats every $n weeks');
  String get repeatsEveryMonth => _t('Gentages hver måned', 'Repeats every month');
  String repeatsEveryNMonths(int n) => _t('Gentages hver $n. måned', 'Repeats every $n months');
  String get customRecurrenceLabel => _t('Brugerdefineret gentagelse', 'Custom recurrence');
  String get cannotEditActivityPermission => _t('Du har ikke adgang til at redigere denne aktivitet.', 'You do not have permission to edit this activity.');
  String get cannotSaveChangesError => _t('Kunne ikke gemme ændringerne.', 'Could not save the changes.');
  String get cannotToggleChecklistPermission => _t('Du har ikke adgang til at ændre tjeklisten.', 'You do not have permission to update the checklist.');
  String get cannotUpdateChecklistError => _t('Kunne ikke opdatere tjeklisten.', 'Could not update the checklist.');
  String get imagePreviewNotSupportedWeb => _t('Billedvisning understøttes ikke i webversionen endnu.', 'Image preview is not supported in the web version yet.');
  String get couldNotDisplayImage => _t('Kunne ikke vise billedet', 'Could not display image');
  String get imageSavedPreviewNotSupportedWeb => _t('Billede gemt, men forhåndsvisning understøttes ikke i webversionen endnu.', 'Image saved, but preview is not supported in the web version yet.');
  String get earnedAfterThisActivity => _t('Kan opnås efter denne aktivitet', 'Can be earned after this activity');
  String earnedAfterNTimes(int n) => _t('Opnås efter $n gange', 'Earned after $n times');

  // ── Calendar Navigation ───────────────────────────────────────────────────

  String weekLabel(int n) => _t('Uge $n', 'Week $n');

  String get everyXPrefix => _t('Hver X', 'Every X');

  List<String> get monthNames => [
    _t('januar', 'January'),
    _t('februar', 'February'),
    _t('marts', 'March'),
    _t('april', 'April'),
    _t('maj', 'May'),
    _t('juni', 'June'),
    _t('juli', 'July'),
    _t('august', 'August'),
    _t('september', 'September'),
    _t('oktober', 'October'),
    _t('november', 'November'),
    _t('december', 'December'),
  ];

  // ── Calendar Screens ──────────────────────────────────────────────────────

  String get dailyCalendarTitle => _t('Daglig kalender', 'Daily calendar');
  String get weeklyCalendarTitle => _t('Ugekalender', 'Weekly calendar');
  String get monthlyCalendarTitle => _t('Månedskalender', 'Monthly calendar');
  String get noActivitiesForDay => _t('Ingen aktiviteter planlagt for denne dag', 'No activities planned for this day');
  String get todayOverview => _t('Dagens overblik', "Today's overview");
  String get completed => _t('Udført', 'Completed');
  String get important => _t('Vigtig', 'Important');
  String get favourite => _t('Favorit', 'Favourite');
  String get personal => _t('Personlig', 'Personal');
  String get noActivities => _t('Ingen aktiviteter', 'No activities');
  String activityCount(int count) => _t(
    '$count aktivitet${count == 1 ? '' : 'er'}',
    '$count activit${count == 1 ? 'y' : 'ies'}',
  );

  List<String> get weekdayNames => [
    _t('Mandag', 'Monday'),
    _t('Tirsdag', 'Tuesday'),
    _t('Onsdag', 'Wednesday'),
    _t('Torsdag', 'Thursday'),
    _t('Fredag', 'Friday'),
    _t('Lørdag', 'Saturday'),
    _t('Søndag', 'Sunday'),
  ];

  List<String> get weekdayShortNames => [
    _t('Man', 'Mon'),
    _t('Tir', 'Tue'),
    _t('Ons', 'Wed'),
    _t('Tor', 'Thu'),
    _t('Fre', 'Fri'),
    _t('Lør', 'Sat'),
    _t('Søn', 'Sun'),
  ];

  String errorLoadActivities(Object e) => _t('Kunne ikke hente aktiviteter: $e', 'Could not load activities: $e');
  String errorLoadWeekActivities(Object e) => _t('Kunne ikke hente ugeaktiviteter: $e', 'Could not load week activities: $e');
  String errorLoadMonthActivities(Object e) => _t('Kunne ikke hente månedsaktiviteter: $e', 'Could not load monthly activities: $e');
  String get errorNoAccessCreate => _t('Du har ikke adgang til at oprette aktiviteter.', 'You do not have access to create activities.');
  String get activitySaved => _t('Aktivitet gemt', 'Activity saved');
  String errorSaveActivity(Object e) => _t('Kunne ikke gemme aktivitet: $e', 'Could not save activity: $e');
  String rewardTriggered(String emoji, String rewardTitle) => _t('Belønning udløst: $emoji $rewardTitle', 'Reward triggered: $emoji $rewardTitle');
  String get errorUpdateActivity => _t('Kunne ikke opdatere aktiviteten.', 'Could not update the activity.');
  String get activityUpdated => _t('Aktivitet opdateret', 'Activity updated');
  String get errorNotLoggedIn => _t('Du er ikke logget ind. Log ind igen.', 'You are not logged in. Please log in again.');

  // ── Rewards Screen ────────────────────────────────────────────────────────

  String get rewardsTitle => _t('Belønninger', 'Rewards');
  String get createRewardDialogTitle => _t('Opret belønning', 'Create reward');
  String get emojiHintReward => _t('f.eks. 🍦', 'e.g. 🍦');
  String get belongsToChild => _t('Tilhører barn', 'Belongs to child');
  String get rewardType => _t('Belønningstype', 'Reward type');
  String get directRewardOption => _t('Direkte belønning', 'Direct reward');
  String get streakRewardOption => _t('Langsigtet belønning', 'Streak reward');
  String get completionCountDirect => _t('Antal gennemførelser', 'Number of completions');
  String get completionCountStreak => _t('Udløses efter X gennemførelser', 'Triggered after X completions');
  String get directRewardHelperText => _t('Direkte belønninger udløses efter 1 gang.', 'Direct rewards trigger after 1 time.');
  String get rewardTitleRequired => _t('Skriv en titel til belønningen.', 'Enter a title for the reward.');
  String get completionCountMin => _t('Antal gennemførelser skal være mindst 1.', 'Number of completions must be at least 1.');
  String get rewardCreated => _t('Belønning oprettet', 'Reward created');
  String get rewardDeleted => _t('Belønning slettet', 'Reward deleted');
  String errorCreateReward(Object e) => _t('Kunne ikke oprette belønning: $e', 'Could not create reward: $e');
  String errorDeleteReward(Object e) => _t('Kunne ikke slette belønning: $e', 'Could not delete reward: $e');
  String errorLoadRewards(Object e) => _t('Kunne ikke hente belønninger: $e', 'Could not load rewards: $e');
  String get needChildFirst => _t('Du skal oprette et barn først, før du kan lave en belønning.', 'You must create a child first before creating a reward.');
  String get profileFilterTitle => _t('Profilfilter', 'Profile filter');
  String get overviewTitle => _t('Oversigt', 'Overview');
  String rewardSummaryAll(int count) => _t('Du har $count belønninger i alt', 'You have $count rewards in total');
  String rewardSummaryProfile(int count, String profileName) => _t('Du har $count belønninger til $profileName', 'You have $count rewards for $profileName');
  String get rewardListTitle => _t('Belønningsliste', 'Reward list');
  String get noRewardsYet => _t('Ingen belønninger endnu', 'No rewards yet');
  String get noRewardsExplanation => _t('Opret en belønning for at kunne knytte den til en aktivitet.', 'Create a reward to attach it to an activity.');

  // ── Create Activity Screen ────────────────────────────────────────────────

  String get newActivityTitle => _t('Ny aktivitet', 'New activity');
  String get editActivityTitle => _t('Rediger aktivitet', 'Edit activity');
  String get emojiHint => _t('f.eks. 🎮', 'e.g. 🎮');
  String get dateLabel => _t('Dato', 'Date');
  String get startLabel => _t('Start', 'Start');
  String get endLabel => _t('Slut', 'End');
  String get titleRequired => _t('Skriv en titel', 'Enter a title');
  String get singleEmojiOnly => _t('Brug kun én emoji', 'Use only one emoji');
  String get fewerSettings => _t('Færre indstillinger', 'Fewer settings');
  String get moreSettings => _t('Flere indstillinger', 'Advanced settings');
  String get notificationsLabel => _t('Notifikationer', 'Notifications');
  String get remindAboutActivity => _t('Påmind mig om denne aktivitet', 'Remind me about this activity');
  String get remindMeLabel => _t('Påmind mig', 'Remind me');
  String get customOption => _t('Tilpasset', 'Custom');
  String get amountLabel => _t('Antal', 'Amount');
  String get enterAmount => _t('Angiv antal.', 'Enter amount.');
  String get reminderMaxDays => _t('Påmindelsen kan højst være 7 dage før aktiviteten.', 'The reminder can be at most 7 days before the activity.');
  String get unitLabel => _t('Enhed', 'Unit');
  String get unitMinutes => _t('minutter', 'minutes');
  String get unitHours => _t('timer', 'hours');
  String get unitDays => _t('dage', 'days');
  String get unitWeeks => _t('uger', 'weeks');
  String get notifStyleLabel => _t('Notifikationsstil', 'Notification style');
  String get repeatActivityLabel => _t('Gentag aktivitet', 'Repeat activity');
  String get recurrenceLabel => _t('Gentagelse', 'Recurrence');
  String get noRecurrence => _t('Ingen gentagelse', 'No recurrence');
  String get daily => _t('Dagligt', 'Daily');
  String get weekly => _t('Ugentligt', 'Weekly');
  String get monthly => _t('Månedligt', 'Monthly');
  String get customRecurrence => _t('Brugerdefineret', 'Custom');
  String get intervalDays => _t('dag(e)', 'day(s)');
  String get intervalWeeks => _t('uge(r)', 'week(s)');
  String get intervalMonths => _t('måned(er)', 'month(s)');
  String get intervalHint => _t('f.eks. 2', 'e.g. 2');
  String get numberMin1 => _t('Skriv et tal på mindst 1', 'Enter a number of at least 1');
  String get recurrenceIntervalMin => _t('Gentagelsesinterval skal være mindst 1.', 'Recurrence interval must be at least 1.');
  String get repeatUntilLabel => _t('Gentag indtil', 'Repeat until');
  String get noEndDate => _t('Ingen slutdato', 'No end date');
  String get removeEndDate => _t('Fjern slutdato', 'Remove end date');
  String get addParticipantsLabel => _t('Tilføj deltagere', 'Add participants');
  String get addExternalParticipantDialog => _t('Tilføj anden deltager', 'Add other participant');
  String get addOtherParticipants => _t('Tilføj andre deltagere', 'Add other participants');
  String get noParticipantsSelected => _t('Ingen deltagere valgt', 'No participants selected');
  String get chooseFromGallery => _t('Vælg fra billeder', 'Choose from gallery');
  String get takePhoto => _t('Tag billede med kamera', 'Take photo with camera');
  String get deleteImageLabel => _t('Slet billede', 'Delete image');
  String get favouriteTooltip => _t('Favorit', 'Favourite');
  String get rewardTooltip => _t('Belønning', 'Reward');
  String get checklistTooltip => _t('Tjekliste', 'Checklist');
  String get addImageTooltip => _t('Tilføj billede', 'Add image');
  String checklistItemHint(int index) => _t('Punkt ${index + 1}', 'Item ${index + 1}');
  String get addChecklistItem => _t('Tilføj punkt', 'Add item');
  String get directRewardLabel => _t('Direkte belønning', 'Direct reward');
  String get directRewardSubtitle => _t('Belønning efter én aktivitet.', 'Reward after one activity.');
  String get selectDirectReward => _t('Vælg direkte belønning', 'Select direct reward');
  String get createNewDirectReward => _t('Opret ny direkte belønning', 'Create new direct reward');
  String get streakRewardLabel => _t('Langsigtet belønning', 'Streak reward');
  String get streakRewardSubtitle => _t('Belønning efter flere gennemførelser.', 'Reward after multiple completions.');
  String get selectStreakReward => _t('Vælg langsigtet belønning', 'Select streak reward');
  String get createNewStreakReward => _t('Opret ny langsigtet belønning', 'Create new streak reward');
  String get streakTargetLabel => _t('Opnås efter X gange', 'Achieved after X times');
  String get streakTargetHint => _t('f.eks. 5', 'e.g. 5');
  String selectedRewardsSummary(String direct, String streak) =>
      _t('Valgt nu: direkte = $direct, langsigtet = $streak', 'Selected: direct = $direct, streak = $streak');
  String get noneSelected => _t('Ingen valgt', 'None selected');
  String get unknownReward => _t('Ukendt belønning', 'Unknown reward');
  String get saveActivityButton => _t('Opret aktivitet', 'Create activity');
  String get saveChangesButton => _t('Gem ændringer', 'Save changes');
  String get imagePreviewNotSupported => _t('Billede valgt, men forhåndsvisning understøttes ikke i webversionen endnu.', 'Image selected, but preview is not supported in the web version yet.');
  String get couldNotLoadImage => _t('Kunne ikke vise billedet', 'Could not display image');
  String get endAfterStart => _t('Sluttid skal være efter starttid.', 'End time must be after start time.');
  String get selectAtLeastOneParticipant => _t('Vælg mindst én deltager.', 'Select at least one participant.');
  String get selectAtLeastOneValidParticipant => _t('Vælg mindst én gyldig deltager.', 'Select at least one valid participant.');
  String get streakTargetValid => _t('Angiv et gyldigt mål for langsigtet belønning.', 'Enter a valid target for the streak reward.');
  String get familyNameReserved => _t('"Familie" er et reserveret navn. Brug valgmuligheden i listen.', '"Family" is a reserved name. Use the option in the list.');
  String participantAlreadyExists(String pName) => _t('"$pName" findes allerede i listen.', '"$pName" already exists in the list.');
  String get createDirectRewardDialogTitle => _t('Opret direkte belønning', 'Create direct reward');
  String get createStreakRewardDialogTitle => _t('Opret langsigtet belønning', 'Create streak reward');
  String get amountMin1 => _t('Antal skal være mindst 1.', 'Amount must be at least 1.');
  String get errorProfileNotFound => _t(
    'Kunne ikke finde din profil. Din bruger er sandsynligvis ikke koblet til en profil i databasen.',
    'Could not find your profile. Your user is probably not linked to a profile in the database.',
  );
  String get errorChildLimitedNoCreate => _t('Denne børneprofil har ikke adgang til at oprette aktiviteter.', 'This child profile does not have access to create activities.');
  String errorLoadProfiles(Object e) => _t('Kunne ikke hente profiler: $e', 'Could not load profiles: $e');
  String errorUploadImage(Object e) => _t('Kunne ikke uploade billede: $e', 'Could not upload image: $e');
  String get errorFamilyOrProfile => _t('Kunne ikke finde familie eller profil.', 'Could not find family or profile.');
  String get childCannotCreateActivities => _t('Denne børneprofil kan ikke oprette aktiviteter.', 'This child profile cannot create activities.');

  String recurrenceEnumLabel(dynamic recurrence) {
    final n = recurrence.toString().split('.').last;
    switch (n) {
      case 'none':    return noRecurrence;
      case 'daily':   return daily;
      case 'weekly':  return weekly;
      case 'monthly': return monthly;
      case 'custom':  return customRecurrence;
      default:        return n;
    }
  }

  String intervalSuffix(dynamic recurrence) {
    final n = recurrence.toString().split('.').last;
    switch (n) {
      case 'daily':   return intervalDays;
      case 'weekly':  return intervalWeeks;
      case 'monthly': return intervalMonths;
      default:        return '';
    }
  }

  // ── Pending Parent Request Screen ─────────────────────────────────────────

  String get pendingApprovalTitle => _t('Afventer godkendelse', 'Awaiting approval');
  String pendingApprovalDescription(String familyName) => _t(
    'Din anmodning om adgang til $familyName er sendt. En eksisterende forælder skal godkende dig, før du får adgang.',
    'Your request for access to $familyName has been sent. An existing parent must approve you before you get access.',
  );
  String get updateStatus => _t('Opdater status', 'Update status');
  String get cancelRequest => _t('Annuller anmodning', 'Cancel request');
  String get cancelRequestDialogTitle => _t('Annuller anmodning', 'Cancel request');
  String get cancelRequestDialogContent => _t('Er du sikker på, at du vil annullere din anmodning?', 'Are you sure you want to cancel your request?');
  String get yesCancelButton => _t('Ja, annuller', 'Yes, cancel');
  String errorUpdateStatus(Object e) => _t('Kunne ikke opdatere status: $e', 'Could not update status: $e');
  String errorCancelRequest(Object e) => _t('Kunne ikke annullere anmodning: $e', 'Could not cancel request: $e');
  String errorLogout(Object e) => _t('Kunne ikke logge ud: $e', 'Could not log out: $e');

  // ── Parent Onboarding Choice Screen ──────────────────────────────────────

  String get familyAccessTitle => _t('Familieadgang', 'Family access');
  String get familyAccessDescription => _t(
    'Vælg om du vil oprette en ny familie eller anmode om adgang til en eksisterende familie.',
    'Choose to create a new family or request access to an existing family.',
  );
  String get createNewFamilyButton => _t('Opret ny familie', 'Create new family');
  String get createNewFamilySubtitle => _t('Start en ny familie og administrér profiler.', 'Start a new family and manage profiles.');
  String get requestAccessButton => _t('Anmod om adgang', 'Request access');
  String get requestAccessSubtitle => _t('Send en anmodning til en eksisterende familie.', 'Send a request to an existing family.');

  // ── Manage Profiles Screen ────────────────────────────────────────────────

  String get manageProfilesTitle => _t('Profiler', 'Profiles');
  String get addChildButton => _t('Tilføj barn', 'Add child');
  String get addChildSheetTitle => _t('Tilføj barn', 'Add child');
  String get addChildSheetSubtitle => _t('Opret en børneprofil og vælg, hvor meget adgang barnet skal have.', 'Create a child profile and choose how much access the child should have.');
  String get roleDescriptionParent => _t('Kan administrere familie, profiler, aktiviteter og indstillinger.', 'Can manage family, profiles, activities and settings.');
  String get roleDescriptionChildLimited => _t('Kan se kalenderen, gennemføre aktiviteter og krydse checklisten af.', 'Can view the calendar, complete activities and check off the checklist.');
  String get roleDescriptionChildExtended => _t('Kan også oprette, redigere og slette egne aktiviteter.', 'Can also create, edit and delete own activities.');
  String get removeParentDialogTitle => _t('Fjern forælder?', 'Remove parent?');
  String removeParentDialogContent(String n) => _t(
    'Vil du fjerne $n som forælder i familien? Personen mister adgang til familiens kalender.',
    'Do you want to remove $n as a parent in the family? The person will lose access to the family calendar.',
  );
  String parentRemoved(String n) => _t('$n blev fjernet som forælder.', '$n was removed as a parent.');
  String errorRemoveParent(Object e) => _t('Kunne ikke fjerne forælder: $e', 'Could not remove parent: $e');
  String get cannotRemoveParentHere => _t('Denne forælder kan ikke fjernes her.', 'This parent cannot be removed here.');
  String get approveParentDialogTitle => _t('Godkend forælder?', 'Approve parent?');
  String approveParentDialogContent(String n) => _t('Vil du give $n adgang som forælder?', 'Do you want to give $n access as a parent?');
  String parentApproved(String n) => _t('$n blev godkendt som forælder.', '$n was approved as a parent.');
  String errorApproveRequest(Object e) => _t('Kunne ikke godkende anmodning: $e', 'Could not approve request: $e');
  String get rejectRequestDialogTitle => _t('Afvis anmodning?', 'Reject request?');
  String rejectRequestDialogContent(String n) => _t('Vil du afvise anmodningen fra $n?', 'Do you want to reject the request from $n?');
  String requestRejected(String n) => _t('Anmodningen fra $n blev afvist.', 'The request from $n was rejected.');
  String errorRejectRequest(Object e) => _t('Kunne ikke afvise anmodning: $e', 'Could not reject request: $e');
  String get childCreatedDialogTitle => _t('Barn oprettet', 'Child created');
  String childCreatedDialogContent(String n) => _t('$n blev oprettet som:', '$n was created as:');
  String get childLoginCodeLabel => _t('Barnets login-kode:', 'Child\'s login code:');
  String get resetChildCodeDialogTitle => _t('Nulstil barnets kode?', 'Reset child\'s code?');
  String resetChildCodeDialogContent(String n) => _t(
    'Vil du oprette en ny login-kode til $n? Den gamle kode virker ikke bagefter.',
    'Do you want to create a new login code for $n? The old code will no longer work.',
  );
  String get resetCodeButton => _t('Nulstil kode', 'Reset code');
  String get newLoginCodeDialogTitle => _t('Ny login-kode', 'New login code');
  String newLoginCodeContent(String n) => _t('Ny kode til $n:', 'New code for $n:');
  String get parentProfileMissing => _t('Forælderprofilen mangler. Prøv at genindlæse.', 'Parent profile missing. Try reloading.');
  String get accessLevelLabel => _t('Adgangsniveau', 'Access level');
  String get limitedAccessOption => _t('Begrænset adgang', 'Limited access');
  String get extendedAccessOption => _t('Udvidet adgang', 'Extended access');
  String get displayNameLabel => _t('Visningsnavn', 'Display name');
  String get displayNameHint => _t('Valgfrit', 'Optional');
  String get nameHint => _t('Fx Adam', 'E.g. Adam');
  String get nameRequired => _t('Skriv barnets navn', 'Enter the child\'s name');
  String get nameTooShort => _t('Navnet er for kort', 'The name is too short');
  String get familyCodeDisplayLabel => _t('Familie kode', 'Family code');
  String get familyCodeDescriptionText => _t('Denne kode bruges sammen med barnets egen login-kode ved børnelogin.', 'This code is used together with the child\'s own login code when logging in as a child.');
  String get noCodeFound => _t('Ingen kode fundet', 'No code found');
  String get pendingRequestsSectionTitle => _t('Afventende forældreanmodninger', 'Pending parent requests');
  String get newParentsInfoTitle => _t('Nye forældre', 'New parents');
  String pendingRequestsInfo(int count) => _t(
    '$count anmodning(er) afventer godkendelse. Godkend kun personer, der skal have fuld forælderadgang til familien.',
    '$count request(s) awaiting approval. Only approve people who should have full parent access to the family.',
  );
  String get removeProfileDialogTitle => _t('Fjern profil?', 'Remove profile?');
  String removeProfileDialogContent(String n) => _t(
    'Hvad vil du gøre med $n? Deaktivering skjuler profilen, men bevarer data. Permanent sletning fjerner profilen fra systemet.',
    'What do you want to do with $n? Deactivation hides the profile but preserves data. Permanent deletion removes the profile from the system.',
  );
  String get deactivateButton => _t('Deaktivér', 'Deactivate');
  String get deletePermanentlyDialogTitle => _t('Slet profil permanent?', 'Delete profile permanently?');
  String deletePermanentlyDialogContent(String n) => _t(
    'Er du sikker på, at du vil slette $n permanent? Dette kan ikke fortrydes. Hvis profilen bruges i aktiviteter eller deltagerlister, kan databasen blokere sletningen.',
    'Are you sure you want to permanently delete $n? This cannot be undone. If the profile is used in activities or participant lists, the database may block the deletion.',
  );
  String get deletePermanentlyButton => _t('Slet permanent', 'Delete permanently');
  String profileDeactivated(String n) => _t('$n blev deaktiveret.', '$n was deactivated.');
  String errorDeactivateProfile(Object e) => _t('Kunne ikke deaktivere profil: $e', 'Could not deactivate profile: $e');
  String profileDeleted(String n) => _t('$n blev slettet.', '$n was deleted.');
  String errorDeleteProfile(Object e) => _t('Kunne ikke slette profil: $e', 'Could not delete profile: $e');
  String get parentCannotBeRemovedHere => _t('Forælderprofilen kan ikke fjernes her.', 'The parent profile cannot be removed here.');
  String get unknownTime => _t('Ukendt tidspunkt', 'Unknown time');
  String requestedAtLabel(String time) => _t('Anmodet: $time', 'Requested: $time');
  String get noProfilesFound => _t('Der blev ikke fundet nogen profiler.', 'No profiles were found.');
  String get familyProfilesHeader => _t('Familleprofiler', 'Family profiles');
  String get removeParentLabel => _t('Fjern forælder', 'Remove parent');
  String get childLoginCodeTitle => _t('Barnets login-kode', 'Child\'s login code');
  String get showCode => _t('Vis', 'Show');
  String get hideCode => _t('Skjul', 'Hide');
  String get newCodeButton => _t('Ny kode', 'New code');
  String get deactivateDeleteButton => _t('Deaktivér / slet', 'Deactivate / delete');
  String get parentAccessInfo => _t('Denne person får fuld forælderadgang, hvis anmodningen godkendes.', 'This person will get full parent access if the request is approved.');
  String get parentOnlyManage => _t('Kun forældre kan administrere profiler.', 'Only parents can manage profiles.');
  String errorLoadProfilesManage(Object e) => _t('Kunne ikke hente profiler: $e', 'Could not load profiles: $e');
  String errorCreateChild(Object e) => _t('Kunne ikke oprette barn: $e', 'Could not create child: $e');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['da', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}
