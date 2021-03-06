%%
%% Copyright (C) 2010 by Tobias Roehm
%%
%% This module contains inference predicates for SRDL Semantic robot description language
%% The SRDL language is used to describe robots, robot components, robot capabilities and robot tasks
%% It is the basis for matchmaking between tasks and robots
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 3 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%

% Definition of srdl module
% For testing purposes all predicates are listed here (such that each predicate can be invoked directly)
:- module(srdl,
    [
	% Matching Predicates based on robot components
        matchRobotAndAction/2,   % (RobotInst, Action)

        % Action inference
        subActions/2,   % (Action, SubActions)
        filterActionListForUnfeasibleActions/3,  %(ActionList, RobotInst, Result)

	% Capability/ Component Inference
	verifyCapAvailability/2,   %(Cap, RobotInst)
        verifyCapAvailabilityFromAssertions/2,   % (Cap, RobotInst) :-
        verifyCapAvailabilityFromComponents/2,   %(Cap, RobotInst)
        checkAvailabilityOfCapList/2,   %(CapList, RobotInst)
        filterReqListForUnmetReq/3,   % (ReqList, RobotInst, Result)
        filterReqListForUnavailableComp/4,   %(reqList, RobotInst, Acc, Result)
	checkCompAvailability/2,   %(Comp, RobotInst)
	filterCapListForNotSupportedCaps/3,   %(CapList, RobotInst, Result)

        % Missing capability and component inference
        returnMissingCapsForAction/3,   % (Action, RobotInst, Result)
        filterActionList/3,   % (ActionList, Acc, Result)
        printMissingComponents/2,   %(Action, RobotInst)
        printMissingComponents/3,   %(Action, RobotInst, Indentation)
        printMissingComponentsForCapList/3,   %(CapList, RobotInst, Indentation)
        printMissingComponentsForSingleCap/3,   % (Cap, RobotInst, Indentation)
        printMissingComponentsForAlternativeList/3,   %(AltList, RobotInst, Indentation)
        printMissingComponentsForSingleAlternative/3,   %(Alt, RobotInst, Indentation)

        missing_components_for_action/3,

        % Learnability Inference
        isLearnableCapability/2,   %(Cap, RobotInst)

	% Action/ Capability Inference
        checkFeasibilityOfActionList/2,   % (ActionList, RobotInst)
        checkActionFeasibility/2,   % (Action, RobotInst)
        checkActionFeasibilityByDependencies/2,   % (Action, RobotInst) :-
        returnRequiredCapForActionList/2,    % (ActionList, Result) :-

        % Experience inference predicates
        computeSuccessProbability/2,   % (Action, SuccessProbability)
	computeSuccessProbabilityFromDescendants/2,   % (Action, ResultProb)
	enumerateSuccessProbabilities/2,   % (ActionList, Result)

	% OWL/ DL Predicates
	propertyValuesFromRestrictions/3,   %(Class, Property, Result)
	hasComponent/2,   %(RobotInst, Component)
        intValueFromHasValueRestriction/3,   % (Subject, Property, IntValue)

	% Tree search Predicates
	treeSearchAllNodes/3,   %(SearchAgendaList, Connective, Result)
	treeSearchLeavesOnly/3,   %(SearchAgendaList, Connective, Result)

	% Utility Predicates
	appendNonredundant/3,   %(L1, L2, Result)
        printAttributesOfComponent/1,   % (Comp)
        printAttributeList/1,   %(AttributeList)
        printSingleAttribute/1,   %(Attr)
        printIndentation/1   %(Indentation)
  ]).

%% Library imports
:- use_module(library('semweb/rdf_db')).
:- use_module(library('semweb/rdfs')).
:- use_module(library('thea/owl_parser')).
:- use_module(library('semweb/owl')).
:- use_module(library('semweb/rdfs_computable')).

%% Load owl file(s)
:- owl_parser:owl_parse('../owl/GetFromRefrigerator.owl', false, false, true).
% :- owl_parser:owl_parse('../owl/SRDL.owl', false, false, true).
% :- owl_parser:owl_parse('../owl/TUM_Rosie.owl', false, false, true).
% :- owl_parser:owl_parse('../owl/PR2.owl', false, false, true).

%% Register namespaces
:- rdf_db:rdf_register_ns(rdf, 'http://www.w3.org/1999/02/22-rdf-syntax-ns#', [keep(true)]).
:- rdf_db:rdf_register_ns(owl, 'http://www.w3.org/2002/07/owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(knowrob, 'http://ias.cs.tum.edu/kb/knowrob.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(srdl, 'http://ias.cs.tum.edu/kb/SRDL.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(srdl_comp, 'http://ias.cs.tum.edu/kb/SRDL_component.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(srdl_cap, 'http://ias.cs.tum.edu/kb/SRDL_capability.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(srdl_action, 'http://ias.cs.tum.edu/kb/SRDL_action.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(rosie, 'http://ias.cs.tum.edu/kb/TUM_Rosie.owl#', [keep(true)]).
:- rdf_db:rdf_register_ns(pr2, 'http://ias.cs.tum.edu/kb/PR2.owl#', [keep(true)]).

% Enable own predicates to use namespace expansion
% For test purposes all predicates are listed here (such each predicate can be used with namespache expansion)
:- rdf_meta

        % Matching Predicates based on robot components
        matchRobotAndAction(r, r),

        % Action  inference
        subActions(r, -),
        filterActionListForUnfeasibleActions(t, r, -),

	% Capability/ Component Inference
	verifyCapAvailability(r, r),
        verifyCapAvailabilityFromAssertions(r, r),
        verifyCapAvailabilityFromComponents(r, r),
        checkAvailabilityOfCapList(t, r),
        filterReqListForUnmetReq(t, r, -),
        filterReqListForUnavailableComp(t, r, t, -),
	checkCompAvailability(r, r),
	filterCapListForNotSupportedCaps(t, r, -),

        % Missing capability and component inference
        returnMissingCapsForAction(r, r, -),
        filterActionList(t, -, -),
        printMissingComponents(r, r),
        printMissingComponents(r, r, -),
        printMissingComponentsForCapList(t, r, -),
        printMissingComponentsForSingleCap(r, r, -),
        printMissingComponentsForAlternativeList(t, r, -),
        printMissingComponentsForSingleAlternative(r, r, -),
        missing_components_for_action(r,r, -),

        % Learnability Inference
        isLearnableCapability(r, r),

	% Action/ Capability Inference
        checkFeasibilityOfActionList(t, r),
        checkActionFeasibility(r, r),
        checkActionFeasibilityByDependencies(r, r),
        returnRequiredCapForActionList(t, -),

        % Experience Inference Predicates
        computeSuccessProbability(r, -),
	computeSuccessProbabilityFromDescendants(r, -),
	enumerateSuccessProbabilities(t, -),

	% OWL/ DL Predicates
	propertyValuesFromRestrictions(r, r, -),
	hasComponent(r, r),
        intValueFromHasValueRestriction(r, r, -),

	% Tree search Predicates
	treeSearchAllNodes(t, r, -),
	treeSearchLeavesOnly(t, r, -),

	% Utility Predicates
	appendNonredundant(t, t, -),
        printAttributesOfComponent(r),
        printAttributeList(t),
        printSingleAttribute(r).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matching Predicates based on robot components
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if robot instance RobotInst is able to execute action Action
matchRobotAndAction(RobotInst, Action) :-
    checkActionFeasibility(Action, RobotInst),
    !.  % commit to first choice


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Action inference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Return all subactions of an action
subActions(Action, SubActions) :-
    % in query 'subAction' is used because in knowrob this relation is used, in SRDL 'hasSubAction' (subproperty of 'subAction)' is used
    treeSearchAllNodes([Action], knowrob:'subAction', SubActions),
    !. % commit to first choice

% Filter the actions in the first argument and return only those that are not feasible on robot RobotInst
filterActionListForUnfeasibleActions(ActionList, RobotInst, Result) :-
    returnUnfeasibleActionsRec(ActionList, RobotInst, [], Result),
    !.  % Commit to first result

% Iterate over list of actions and return only that actions that are not feasible on robot RobotInst
returnUnfeasibleActionsRec([], _, Acc, Acc).
returnUnfeasibleActionsRec([H|T], RobotInst, UnsupportedActions, Result) :-
   returnUnfeasibleActionsRec(T, RobotInst, UnsupportedActions, TmpResult),
   (
       checkActionFeasibility(H, RobotInst)
   ->
       Result = TmpResult
   ;
       appendNonredundant([H], TmpResult, Result)
   ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Capability/ Component Inference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if capability Cap is available on robot RobotInst
verifyCapAvailability(Cap, RobotInst) :-
    % CASE 1: cap is directly asserted
    (
        verifyCapAvailabilityFromAssertions(Cap, RobotInst);
    % CASE 2: cap is available based on components of RobotInst
        verifyCapAvailabilityFromComponents(Cap, RobotInst)
    ),
    !.  % Commit to first result

% check if capability Cap is available on robot RobotInst based on assertions
% Assertions of capabilities are made in TBox on Robot class using restrictions on property 'hasCapability'
verifyCapAvailabilityFromAssertions(Cap, RobotInst) :-
    rdfs_individual_of(RobotInst, RobotClass),  % using rdfs_individual_of because owl_individual seems to have a bug
    owl_subclass_of(RobotClass,  srdl:'SrdlRobot'),
    propertyValuesFromRestrictions(RobotClass, srdl:'hasCapability', CapList),
    member(Cap, CapList),
    !. % Commit to first result

% Check for capability Cap if all components needed are available on robot instance RobotInst
verifyCapAvailabilityFromComponents(Cap, RobotInst) :-
    % search cap provision alternative that provides cap
    owl_subclass_of(Alt, srdl:'CapabilityProvisionAlternative'),
    propertyValuesFromRestrictions(Alt, srdl:'providesCapability', CapList),
    member(Cap, CapList),
    (
        owl_subclass_of(Cap, srdl_cap:'PrimitiveCapability')
    ->
        % CASE 1: capability is a primitive capability
        propertyValuesFromRestrictions(Alt, srdl:'needsComponent', ReqList),  % collect all requirements for current alternative
        ReqList \== [],
        % OLD: filterReqListForUnavailableComp(ReqList, RobotInst)
        filterReqListForUnmetReq(ReqList, RobotInst, UnmetReq),
        UnmetReq == []
    ;
        % CASE 2: capability is a composite capability
        % collect all requirements for current alternative
        propertyValuesFromRestrictions(Alt, srdl_cap:'hasSubCapability', SubCapList),
        SubCapList \== [],
        checkAvailabilityOfCapList(SubCapList, RobotInst),

        % check if there are component requirements
        ( (propertyValuesFromRestrictions(Alt, srdl:'needsComponent', ReqList),
           ReqList \== [])
           -> (filterReqListForUnmetReq(ReqList, RobotInst, UnmetReq),
               UnmetReq == []) ;
              (true) )
    ),
    !. % Commit to first result

% Iterate over list of capabilities and check if every capability is fulfilled
checkAvailabilityOfCapList([], _).
checkAvailabilityOfCapList([H|T], RobotInst) :-
    verifyCapAvailability(H, RobotInst),
    checkAvailabilityOfCapList(T, RobotInst).

% Collect all requirements in list parameter that are not met
% This predicate only calls predicate filterReqListForUnavailableComp
filterReqListForUnmetReq(ReqList, RobotInst, Result) :-
    filterReqListForUnavailableComp(ReqList, RobotInst, [], Result).

% iterate over component list and return those components that are NOT available on RobotInst
filterReqListForUnavailableComp([], _, Acc, Acc).
filterReqListForUnavailableComp([H|T], RobotInst, Acc, Result) :-
    % component requirement -> check if component is available
    (
        checkCompAvailability(H, RobotInst)
    ->
        TmpList = []
    ;
        TmpList = [H]
    ),
    filterReqListForUnavailableComp(T, RobotInst, Acc, ResultTmp),
    appendNonredundant(ResultTmp, TmpList, Result).

% check if (an instance of) component Comp is attached to robot instance RobotInst
checkCompAvailability(Comp, RobotInst) :-
    owl_individual_of(CompInst, Comp),
    hasComponent(RobotInst, CompInst),
    !.

% Compute all elements of CapList that are not supported by robot RobotInst due to its components
% This predicate just calls predicate returnNotSupportedCapsRec
filterCapListForNotSupportedCaps(CapList, RobotInst, Result) :-
    returnNotSupportedCapsRec(CapList, RobotInst, [], Result),
    !.  % commit to first result

% iterate over capability list and return those capabilities that are NOT available on RobotInst
returnNotSupportedCapsRec([], _, NotSupportedCaps, NotSupportedCaps).
returnNotSupportedCapsRec([H|T], RobotInst, NotSupportedCaps, Result) :-
    returnNotSupportedCapsRec(T, RobotInst, NotSupportedCaps, TmpResult),
    (
        verifyCapAvailability(H, RobotInst)
    ->
        Result = TmpResult
    ;
        appendNonredundant([H], TmpResult, Result)
    ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Missing capability and component inference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Return all capbilities that are needed for action Action but are not fulfilled
% CAUTION: In this predicate only the missing capabilities of actions are considered, that are unfeasible, that are leaves in action tree and that have a direct subclass which is also a subclass of srdl:'SrdlRobotAction' which carries the capability dependencies
returnMissingCapsForAction(Action, RobotInst, Result) :-
    (
         checkActionFeasibility(Action, RobotInst)
    ->
         % if action is feasibly return warning
         ( print('Action "') , print(Action), print('" is feasible and hence there are not capabilities that are missing.'), fail )
    ;
        % all sub actions
        subActions(Action, AllSubActions),
        % all sub actions that are not feasible
        filterActionListForUnfeasibleActions(AllSubActions, RobotInst, UnfeasibleSubActions),

        % filter to have only actions that are leafs in action tree
        findall(X,
                ( member(X, UnfeasibleSubActions),
                  treeSearchLeavesOnly([X], knowrob:'subAction', TmpSubActions),
                  delete(TmpSubActions, X, TmpSubActionsWithoutX),
                  TmpSubActionsWithoutX = []),
                UnfeasibleLeafSubActions),

        % filter to have only those actions that have a subclass which is also a subclass of srdl:'SrdlRobotAction'
        filterActionList(UnfeasibleLeafSubActions, [], RelevantSubActions),

        % collect capabilities of primary unfeasible sub actions
        returnRequiredCapForActionList(RelevantSubActions, RequiredCap),

        % filter to have only capabilites that are not supported
        filterCapListForNotSupportedCaps(RequiredCap, RobotInst, MissingCaps),

        % return value
        Result = MissingCaps
    ),
    !.  % Commit to first result

% iterate over action list and return for action a the subclass which is also subclass of srdl:'SrdlRobotAction' if one exists, otherwise ignore a
filterActionList([], Result, Result).
filterActionList([A|T], Acc, Result) :-
    filterActionList(T, Acc, TmpResult),
    (
        owl_subclass_of(Sub, A),
        owl_subclass_of(Sub, srdl:'SrdlRobotAction')
    ->
        appendNonredundant(TmpResult, [Sub], Result)
    ;
        Result = TmpResult
    ).


%
% Return a list of all components missing for action Act
%
missing_components_for_action(Action, Robot, Components) :-

  findall(Component, (% determine missing capabilities for this action:
                      returnRequiredCapForActionList([Action], MissingCaps1),

                      % missing capabilites for sub-actions:
                      returnMissingCapsForAction(Action, Robot, MissingCaps2),

                      append(MissingCaps1, MissingCaps2, MissingCaps),
                      member(Cap, MissingCaps),


                      % check for each capability which components are missing
                      findall(UnmetReq, ( owl_subclass_of(Alt, srdl:'CapabilityProvisionAlternative'),
                                    propertyValuesFromRestrictions(Alt, srdl:'providesCapability', CapList),
                                    member(Cap, CapList),

                                    propertyValuesFromRestrictions(Alt, srdl:'needsComponent', ReqList),
                                    filterReqListForUnmetReq(ReqList, Robot, UnmetReq)
                                  ), UnmetReqs),

                      flatten(UnmetReqs, Component)),
          CompLists),
  flatten(CompLists, Components).



% Print components that are missing for action Action on robot RobotInst
% This predicate only calls predicate printMissingComponents/3
printMissingComponents(Action, RobotInst) :-
    printMissingComponents(Action, RobotInst, 0),
    !.

% Print components that are missing for action Action on robot RobotInst
printMissingComponents(Action, RobotInst, Indentation) :-
    (
        returnMissingCapsForAction(Action, RobotInst, MissingCap),
        MissingCap \== []
    ->
       printMissingComponentsForCapList(MissingCap, RobotInst, Indentation)
    ;
       fail
    ),
    !.  % Commit to first result

% Iterate over cap list and print missing components for every cap
printMissingComponentsForCapList([], _, _).
printMissingComponentsForCapList([H|T], RobotInst, Indentation) :-
    printMissingComponentsForSingleCap(H, RobotInst, Indentation),
    printMissingComponentsForCapList(T, RobotInst, Indentation).

% print missing components for a single cap
printMissingComponentsForSingleCap(Cap, RobotInst, Indentation) :-
    % owl_subclass_of(Cap, srdl_cap:'PrimitiveCapability'),
    nl, printIndentation(Indentation), print('### CAPABILITY ### '), print(Cap), nl,
    findall(X,
              (
                  owl_subclass_of(X, srdl:'CapabilityProvisionAlternative'),
                  propertyValuesFromRestrictions(X, srdl:'providesCapability', CapList),
                  member(Cap, CapList)
              ),
             AltList),
    printMissingComponentsForAlternativeList(AltList, RobotInst, Indentation).

% Iterate over alternatives list and print missing components for every alternative of a capability
printMissingComponentsForAlternativeList([], _, _).
printMissingComponentsForAlternativeList([H|T], RobotInst, Indentation) :-
    printMissingComponentsForSingleAlternative(H, RobotInst, Indentation),
    printMissingComponentsForAlternativeList(T, RobotInst, Indentation).

% print missing components for a single alternative
printMissingComponentsForSingleAlternative(Alt, RobotInst, Indentation) :-
    printIndentation(Indentation), print('# Provision alternative # '), print(Alt), nl,
    (
        owl_subclass_of(Alt, srdl:'PrimitiveCapabilityAlternative')
    ->
        % CASE 1: primitive cap
        % collect all requirements
        propertyValuesFromRestrictions(Alt, srdl:'needsComponent', ReqList),
        % calculate and print unmet requirements
        filterReqListForUnmetReq(ReqList, RobotInst, UnmetReq),
        printIndentation(Indentation), print('Unmet requirements: '), nl, printIndentation(Indentation), print(UnmetReq), nl,
        % calculate and print  met requirements
        findall(X, ( member(X, ReqList), \+ member(X, UnmetReq) ), MetReq),
        printIndentation(Indentation), print('Met requirements: '), nl, printIndentation(Indentation), print(MetReq), nl
    ;
        % CASE 2: composite cap
        printIndentation(Indentation), print('Capability provision alternative "'), print(Alt) , print('" is a composite capability provision alternative.'), nl,


        % collect all requirements
        propertyValuesFromRestrictions(Alt, srdl:'needsComponent', ReqList),
        % calculate and print unmet requirements
        filterReqListForUnmetReq(ReqList, RobotInst, UnmetReq),
        printIndentation(Indentation), print('Unmet requirements: '), nl, printIndentation(Indentation), print(UnmetReq), nl,


        printIndentation(Indentation), print('In the following alternatives for subcapabilities are shown:'), nl, printIndentation(Indentation), print('==>'),

        propertyValuesFromRestrictions(Alt, srdl_cap:'hasSubCapability', SubCapList),
        NextIndentation is Indentation + 4,
        printMissingComponentsForCapList(SubCapList, RobotInst, NextIndentation),

        printIndentation(Indentation), print('<==')
    ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Learnability Inference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if capability Cap is potentially learnable (meaning it could be learned if training data are available)
isLearnableCapability(Cap, RobotInst) :-
    owl_subclass_of(Cap, srdl_cap:'Capability'),
    % Cond 1: no missing hardware component
    \+ ( propertyValuesFromRestrictions(Cap, srdl:'needsComponent', ReqList),
         member(HwComp, ReqList),
         owl_subclass_of(HwComp, srdl_comp:'HardwareComponent'),
         checkCompAvailability(HwComp, RobotInst)
       ),
    % Cond 2: learning component existent
    propertyValuesFromRestrictions(Cap, srdl:'hasLearningComponent', LearnCompList),
    member(LearningComp, LearnCompList),
    checkCompAvailability(LearningComp, RobotInst),
    !. % Commit to first choice


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Action/ Capability Inference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Iterate over action list and verify that each action can be executed by robot RobotInst
checkFeasibilityOfActionList([], _).
checkFeasibilityOfActionList([H|T], RobotInst) :-
    checkActionFeasibility(H, RobotInst),
    checkFeasibilityOfActionList(T, RobotInst).

% Check if an action Action is feasible on robot RobotInst
checkActionFeasibility(Action, RobotInst) :-
    owl_subclass_of(Action, knowrob:'PurposefulAction'),
    % CASE 1: capability dependencies for Action and all sub events are met
    ( (
        checkActionFeasibilityByDependencies(Action, RobotInst)
    )
    ;
    % CASE 2: subclass SubAction of Action exist and is feasible
    (
        owl_subclass_of(ActionSubclass, Action),
        ActionSubclass \== Action,  % TODO: make sure not to go into infty loop in case of owl:equivalentClass
        checkActionFeasibility(ActionSubclass, RobotInst)
    ) ),
    !.  % Commit to first result

% check if an action is feasible by checking capability dependencies of action and all of its direct childs
checkActionFeasibilityByDependencies(Action, RobotInst) :-
    % check dependencies of Action
    propertyValuesFromRestrictions(Action, srdl:'hasCapabilityDependency', ActionCapDep),
    checkAvailabilityOfCapList(ActionCapDep, RobotInst),

    % if no dependencies of action are found check dependencies of childs
    (
        ActionCapDep == []
    ->
        (
        propertyValuesFromRestrictions(Action, knowrob:'subAction', DirectSubActions),
        checkFeasibilityOfActionList(DirectSubActions, RobotInst)
        )
    ;
        true
    ),

    % make sure that either capability dependencies or sub events are specified MT: WHY?
    (
        ( DirectSubActions == [] , ActionCapDep == [] )
    ->
        fail
    ;
        true
    ),
    !.  % commit to first result


% Collect required capabilities for a list of tasks
returnRequiredCapForActionList([], []).
returnRequiredCapForActionList([H|T], CapList) :-
    propertyValuesFromRestrictions(H, srdl:'hasCapabilityDependency', L1),
    returnRequiredCapForActionList(T, L2),
    appendNonredundant(L1, L2, CapList).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Experience Inference Predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute successProbability of a cyc:PurposefulAction from its attempt and success numbers
% attempt and success numbers can be directly asserted or computed from childs in action tree
computeSuccessProbability(Action, SuccessProbability) :-
    owl_subclass_of(Action, knowrob:'PurposefulAction'),
    (
        % jump to subclass of action that is also a subclass of srdl:'SrdlRobotAction'
        owl_subclass_of(RobotAction, Action),
        owl_subclass_of(RobotAction, srdl:'SrdlRobotAction'),
        % Bind NumAttempts and NumSuccesses
        intValueFromHasValueRestriction(RobotAction, srdl:'hasNumOfSuccesses', NumSuccesses),
        intValueFromHasValueRestriction(RobotAction, srdl:'hasNumOfAttempts', NumAttempts)
    ->
        % Compute success probability
        SuccessProbability is NumSuccesses / NumAttempts
    ;
        (
            computeSuccessProbabilityFromDescendants(Action, TmpProb)
        ->
            SuccessProbability = TmpProb
        ;
            fail
        )
    ),
    !. % Commit to first result

% Compute success probability on the base of all descendants using min prob
computeSuccessProbabilityFromDescendants(Action, ResultProb) :-
    treeSearchAllNodes([Action], knowrob:'subAction', SubActionsTmp),
    delete(SubActionsTmp, Action, SubActions),
    (
       SubActions == []
    ->
        % in case of a taks with no descendants with no attempt and success numbers: fail
        fail
    ;
        % in case of a task with subtasks: enumerate all success probabilities and return min
        enumerateSuccessProbabilities(SubActions, ProbList),
        min_list(ProbList, MinProb),
        ResultProb = MinProb
    ),
    !.  % Commit to first solution

% Compute success probabilities for actions in ActionList
% Just calls predicate enumerateSuccessProbabilitiesRec
enumerateSuccessProbabilities(ActionList, Result) :-
    enumerateSuccessProbabilitiesRec(ActionList, [], Result).

% Compute success probabilities for each action in action list and return all success probabilities in a list
enumerateSuccessProbabilitiesRec([], Acc, Acc).
enumerateSuccessProbabilitiesRec([H|T], Acc, Result) :-
    enumerateSuccessProbabilitiesRec(T, Acc, TmpResult),
    (
        computeSuccessProbability(H, HeadSuccessProb)
    ->
        appendNonredundant(TmpResult, [HeadSuccessProb], Result)
    ;
        Result = TmpResult
    ).


%%%%%%%%%%%%%%%%%%%%%
% OWL/ DL Predicates
%%%%%%%%%%%%%%%%%%%%%

% Collect all property values of someValuesFrom-restrictions of a class
% Input:  Class - base class/ class whose restrictions are being considered
%         Property - property whose restrictions in Class are being considered
% Output: Result - list of all classes that appear in a restriction of a superclass of Class along Property
propertyValuesFromRestrictions(Class, Property, Result) :-
    % 1) all restrictions that are contained in an intersection
    findall(X, (
                        owl_subclass_of(Class, S),
                        owl_has(S, rdfs:subClassOf, D),
                        owl_has(D, owl:intersectionOf, I),
                        rdfs_member(R, I),
                        owl_has(R, owl:onProperty, P),
                        rdfs_subproperty_of(P, Property),
                        ( owl_has(R, owl:someValuesFrom, X) ; owl_has(R, owl:allValuesFrom, X) )
                      ),
               L1),
    % 2) all restrictions that are a single restriction (not in an intersection)
    findall(X, (
                        owl_subclass_of(Class, S),
                        owl_has(S, rdfs:subClassOf, R),
                        owl_has(R, owl:onProperty, P),
                        rdfs_subproperty_of(P, Property),
                        ( owl_has(R, owl:someValuesFrom, X) ; owl_has(R, owl:allValuesFrom, X) )
                      ),
               L2),
    % Merge lists and remove duplicates
    appendNonredundant(L1, L2, Result),
    !.  % commit to first solution

% Calculate relation 'hasComponent' between a robot instance and a component
% This relation is hard coded as a predicate because Prolog OWL does not support property chains
hasComponent(S, O) :-
    owl_has(S, srdl:'hasComponent', O).

% hard coded property chain for software component
hasComponent(S, O) :-
    owl_has(S, srdl:'hasHardwareComponent', HwComp),
    owl_has(HwComp, srdl_comp:'executesSoftware', O).

% considering composite components
hasComponent(S, CompositeComp) :-
    owl_individual_of(CompositeComp, srdl_comp:'ComponentComposition'),
    owl_has(CompositeComp, srdl_comp:'hasBaseLinkOfComposition', BaseComp),
    hasComponent(S, BaseComp).

% Read integer value from a owl:'hasValue' - restriction on property Property on subject Subject and return it as an atom
intValueFromHasValueRestriction(Subject, Property, IntValue) :-
    owl_subclass_of(Subject, Desc),
    owl_has(Desc, owl:'onProperty',  Property),
    owl_has(Desc, owl:'hasValue', NumLiteral),
    NumLiteral = literal(NumType),
    NumType = type(_, NumTerm),
    term_to_atom(IntValue, NumTerm),
    !.


%%%%%%%%%%%%%%%%%%%%%%%%%
% Tree search Predicates
%%%%%%%%%%%%%%%%%%%%%%%%%

% Tree search that collects all nodes in the tree
% Expansion of first node via property values in restrictions of class descriptions
% Input:  List - search agenda
%         Connective - The OWL property that spans the tree (via restrictions)
% Output: Result - the list of all nodes in the tree
treeSearchAllNodes([], _, []).
treeSearchAllNodes([H|T], Connective, Result) :-
    propertyValuesFromRestrictions(H, Connective, L1),
    appendNonredundant(T, L1, SearchAgenda),
    treeSearchAllNodes(SearchAgenda, Connective, TmpResult),
    appendNonredundant(TmpResult, [H], Result).

% Tree search that collects only leaf nodes in the tree
% Expansion of first node via property values in restrictions of class descriptions
% Input:  List - search agenda
%         Connective - The OWL property that spans the tree (via restrictions)
% Output: Result - the list of all leaf nodes in the tree
treeSearchLeavesOnly([], _, []).
treeSearchLeavesOnly([H|T], Connective, Result) :-
    propertyValuesFromRestrictions(H, Connective, L1),
    appendNonredundant(T, L1, SearchAgenda),
    treeSearchLeavesOnly(SearchAgenda, Connective, TmpResult),
    (
      L1 == []
   ->
      appendNonredundant(TmpResult, [H], Result)
    ;
      Result = TmpResult
    ),
    !.  % commit to first choice


%%%%%%%%%%%%%%%%%%%%%
% Utility Predicates
%%%%%%%%%%%%%%%%%%%%%

% Append List L2 to L1
% nonredundant append: for each member m of L2 it is checked if it is already member of L1
% member m is added only if it is not yet member of L1
appendNonredundant(L, [], L).
appendNonredundant(L1, [H|T], Result) :-
    (
      %member(H, L1)
      memberchk(H, L1)
   ->
      appendNonredundant(L1, T, Result)
    ;
      ( append([H], L1, L2), appendNonredundant(L2, T, Result) )
    ),
    !.  % Commit to first choice

% print all attributes of a component
printAttributesOfComponent(Comp) :-
    owl_individual_of(Comp, srdl_comp:'Component'),
    print('Attributes of component '), print(Comp), nl, print('-----'), nl,
    findall(X, owl_has(Comp, srdl_comp:'hasAttribute', X),AttList),
    printAttributeList(AttList),
    !.

% iterate over attribute list and print each attribute
printAttributeList([]).
printAttributeList([H|T]) :-
    printSingleAttribute(H),
    printAttributeList(T).

% print name, value and unit of measure of a single attribute
printSingleAttribute(Attr) :-
    owl_has(_, srdl_comp:'hasAttribute', Attr),
    % print('Attribute '),

    % attribute name
    (
        owl_has(Attr, srdl_comp:'hasAttributeName', NameLiteral)
    ->
        NameLiteral = literal(Name),
        print(Name)
    ;
        print('unspecified name')
    ),
    print(' = '),

    % attribute value
    (
        owl_has(Attr, srdl_comp:'hasAttributeValue', ValueLiteral)
    ->
        ValueLiteral = literal(Value),
        print(Value)
    ;
        print('unspecified value')
    ),
    print(' '),

    % attribute unit of measure
    (
        owl_has(Attr, srdl_comp:'hasAttributeUnitOfMeasure', UomLiteral)
    ->
        UomLiteral = literal(Uom),
        print(Uom)
    ;
        print('unspecified unit of measure')
    ),
    nl,
    !.

% Print Indentation number of spaces recursively
% This is used for formatting print output
printIndentation(0).
printIndentation(Indentation) :-
    print(' '),
    X is Indentation - 1,
    printIndentation(X),
    !.
