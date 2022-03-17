import Foundation

enum BoundaryConditionsError: LocalizedError {
    case noTargetItemsAvailable
    case nilKeyItem
    case listIsEmpty
    case itemTypeMismatch
}

extension BoundaryConditionsError {
    var errorDescription: String? {
        switch self {
        case .noTargetItemsAvailable:
            return "No target items available"
        case .nilKeyItem:
            return "Key item is nil"
        case .listIsEmpty:
            return "List is empty"
        case .itemTypeMismatch:
            return "Got a dataset of items with different types"
        }
    }
}

func main() {
    let tasks = [
        MostFrequentItemTask(dataSet: [1, 1, 1, 2, 3, 4, 4, 1], targetItem: 2),
        MostFrequentItemTask(dataSet: [1, 1, 1, 2, 3, 4, 4, 1], targetItem: 1)
    ]
    let stringTasks = [
        MostFrequentItemTask(dataSet: ["red", "green", "blue", "green", "blue"], targetItem: "green")
    ]
    let mixedTypesTasks = [
        MostFrequentItemTask(dataSet: ["red", "green", "blue", "green", "blue"], targetItem: nil),
        MostFrequentItemTask<AnyHashable>(dataSet: nil, targetItem: nil),
        MostFrequentItemTask(dataSet: nil, targetItem: 2),
        MostFrequentItemTask(dataSet: [1, "fish", 1, 2, "fish"], targetItem: 2)
    ]
    let fringeConditionsTasks = [
        MostFrequentItemTask(dataSet: [1, 3], targetItem: 0),
        MostFrequentItemTask(dataSet: [2], targetItem: 2),
        MostFrequentItemTask(dataSet: [-1, 40, 2, 40, 3, 40, 2], targetItem: 40),
    ]
    for task in tasks {
        task.execute()
    }
    for task in stringTasks {
        task.execute()
    }
    for task in mixedTypesTasks {
        task.execute()
    }
    for task in fringeConditionsTasks {
        task.execute()
    }
}

// MARK: - Task structure for testcases testing using a command pattern

struct MostFrequentItemTask<ItemType> where ItemType: Hashable {
    
    // MARK: - Types
    
    private typealias ItemsDictionary = Dictionary<ItemType, ItemProperties>
    
    /// Auxiliary structure used as a value for a dictionary
    private struct ItemProperties: Equatable {
        var occurences: Int
        var distance: Int
        // MARK: - Private methods
        
        mutating func set(distance: Int) {
            self.distance = distance
        }
        
        mutating func increaseOccurences() {
            self.occurences += 1
        }
        
        mutating func decreaseOccurences() {
            self.occurences -= 1
        }
    }
    
    // MARK: - Properties
    
    let dataSet: [ItemType]?
    let targetItem: ItemType?
    
    // MARK: - Public methods
    
    func execute() {
        do {
            let answer = try self.firstMostFrequentItem(amongList: dataSet, afterTheFirstOccurenceOfItem: targetItem)
            print(answer)
        } catch {
            print(error)
        }
    }
    
    // MARK: - Private methods
    
    /**
     Has complexity of roughly O(n) (without using checkTypesConsistency method):
         0.49 ms for 1000 ints
         1.3 ms for 2000 ints
         1.74 ms for 4000 ints
         3.95 ms for 8000 ints
         8.86 ms for 16000 ints
         16.07 ms for 32000 ints
     Function makes use of O(1) retrieval and O(logn) insertion complexity of dictionary,
     instead of using straightforward quicksort insertions to form a list and then iterate
     through it.
     */
    private func firstMostFrequentItem(amongList list: [ItemType]?, afterTheFirstOccurenceOfItem keyItem: ItemType?) throws -> (ItemType, Int) {
        guard let list = list,
              !list.isEmpty else {
                  throw BoundaryConditionsError.listIsEmpty
              }
        guard let keyItem = keyItem else {
            throw BoundaryConditionsError.nilKeyItem
        }
        do {
            try checkTypesConsistency(forListOfItems: list)
            var firstAppearedKeyItem: ItemType?
            let dictionary = makeDictionaryOfCandidates(fromList: list,
                                                        keyItem: keyItem,
                                                        firstAppearedKeyItem: &firstAppearedKeyItem)
            guard let firstAppearedKeyItem = firstAppearedKeyItem else {
                throw BoundaryConditionsError.noTargetItemsAvailable
            }
            let maximumOccurencesCount = try getMaximumOccurencesCount(fromDictinary: dictionary)
            let targetItem = try getLeastDistancedItem(fromDictionary: dictionary,
                                                       firstAppearedKeyItem: firstAppearedKeyItem,
                                                       maximumOccurencesCount: maximumOccurencesCount)
            return (targetItem, maximumOccurencesCount)
        } catch {
            throw error
        }
    }
    
    /** Dictionary with a key of target element candidates with their distances from
        the key item and a value of number of occurences of target candidate items
     */
    @inline(__always) private func makeDictionaryOfCandidates(fromList list: [ItemType],
                                                              keyItem: ItemType,
                                                              firstAppearedKeyItem: inout ItemType?) -> ItemsDictionary {
        var dictionary: ItemsDictionary = [:]
        var didModifyPropertiesOfFirstAppearedKeyItemCandidate = false
        for (offset, item) in list.enumerated() {
            if item != keyItem && dictionary.isEmpty {
                continue
            }
            if item == keyItem && firstAppearedKeyItem == nil {
                firstAppearedKeyItem = item
                dictionary[item] = .init(occurences: 0, distance: 0)
                continue
            }
            guard let firstAppearedKeyItem = firstAppearedKeyItem,
                  let firstAppearedKeyItemProperties = dictionary[firstAppearedKeyItem] else {
                continue
            }
            let distanceFromFirstAppearedKeyItem = firstAppearedKeyItemProperties.distance.distance(to: offset)
            if !didModifyPropertiesOfFirstAppearedKeyItemCandidate && item == keyItem {
                didModifyPropertiesOfFirstAppearedKeyItemCandidate = true
                dictionary[item]?.set(distance: distanceFromFirstAppearedKeyItem)
            }
            if dictionary[item] != nil {
                dictionary[item]!.increaseOccurences()
            } else {
                dictionary[item] = .init(occurences: 1, distance: distanceFromFirstAppearedKeyItem)
            }
        }
        return dictionary
    }

    /**
     Retrieves maximum number of occurences among all candidates
     */
    @inline(__always) private func getMaximumOccurencesCount(fromDictinary dictionary: ItemsDictionary) throws -> Int {
        if dictionary.isEmpty {
            throw BoundaryConditionsError.noTargetItemsAvailable
        }
        var maximumOccurencesCount = dictionary.first!.value.occurences
        for (_, candidateProperties) in dictionary.dropFirst() {
            if candidateProperties.occurences > maximumOccurencesCount {
                maximumOccurencesCount = candidateProperties.occurences
            }
        }
        return maximumOccurencesCount
    }
    
    /**
     Gets least distanced common item from the first appeared in list key item using
     already calculated maximum count of appearances among candidates
     */
    @inline(__always) private func getLeastDistancedItem(fromDictionary dictionary: ItemsDictionary,
                                                         firstAppearedKeyItem: ItemType,
                                                         maximumOccurencesCount: Int) throws -> ItemType {
        if dictionary.isEmpty {
            throw BoundaryConditionsError.noTargetItemsAvailable
        }
        var targetItem: ItemType?
        var leastDistanceOfCandidateTargetItem = Int.max
        for (candidateItem, candidateProperties) in dictionary {
            if candidateProperties.occurences == maximumOccurencesCount && candidateProperties.distance < leastDistanceOfCandidateTargetItem {
                leastDistanceOfCandidateTargetItem = candidateProperties.distance
                targetItem = candidateItem
            }
        }
        if let targetItem = targetItem {
            return targetItem
        } else {
            throw BoundaryConditionsError.noTargetItemsAvailable
        }
    }
    
    /**
     Reassuring that all items in an input dataset must be the same throught the list
     and the list must contain more than one item. Makes an algorithm heavier due to
     O(n^2) complexity, but it's not an essential part.
     */
    @inline(__always) private func checkTypesConsistency(forListOfItems list: [ItemType]) throws {
        for itemIndex in 0..<list.count {
            for selectedItemIndex in itemIndex..<list.count {
                let selectedItem = list[selectedItemIndex] as AnyHashable
                let item = list[itemIndex] as AnyHashable
                if type(of: selectedItem.base.self) != type(of: item.base.self) {
                    throw BoundaryConditionsError.itemTypeMismatch
                }
            }
        }
        guard list.count > 1 else {
            throw BoundaryConditionsError.noTargetItemsAvailable
        }
    }
}

main()
