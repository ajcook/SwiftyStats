//
//  SSHypothesisTesting-Randomness.swift
//  SwiftyStats
//
//  Created by Volker Thieme on 20.07.17.
//
/*
 Copyright (c) 2017 Volker Thieme
 
 GNU GPL 3+
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, version 3 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import Foundation
import os.log

extension SSHypothesisTesting {
    // MARK: Randomness
    
    /// Performs the runs test for the given sample. Tests for randomness.
    /// ### Important Note ###
    /// It is important that the data are numerical. To recode non-numerical data follow the procedure as described below.<br/>
    ///
    /// ````
    /// Suppose the original data is a string containing only "H" and "L":
    /// HLHHLHHLHLLHLHHL
    /// Setting "H" = 1 and "L" = 3 results in the recoded sequence:
    /// 1311311313313113
    /// In this case a cutting point of 2 must be used.
    /// Setting "H" = 1 and "L" = 2 results in the recoded sequence:
    /// 1211211212212112
    /// In this case a cutting point of 1.5 must be used.
    /// ````
    ///
    /// - Parameter data: Array<Double>
    /// - Parameter alpha: Alpha
    /// - Parameter useCuttingPoint: SSRunsTestCuttingPoint.median || SSRunsTestCuttingPoint.mean || SSRunsTestCuttingPoint.mode || SSRunsTestCuttingPoint.userDefined
    /// - Parameter cP: A user defined cutting point. Must not be nil if SSRunsTestCuttingPoint.userDefined is set
    /// - Throws: SSSwiftyStatsError iff data.sampleSize < 2
    public class func runsTest(array: Array<Double>!, alpha: Double!, useCuttingPoint useCP: SSRunsTestCuttingPoint, userDefinedCuttingPoint cuttingPoint: Double?, alternative: SSAlternativeHypotheses) throws -> SSRunsTestResult {
        if array.count < 2 {
            os_log("sample size is expected to be >= 2", log: log_stat, type: .error)
            throw SSSwiftyStatsError.init(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        do {
            return try SSHypothesisTesting.runsTest(data: SSExamine<Double>.init(withArray: array, name: nil,  characterSet: nil), alpha: alpha, useCuttingPoint: useCP, userDefinedCuttingPoint: cuttingPoint, alternative: alternative)
        }
        catch {
            throw error
        }
    }
    
    
    /// Performs the runs test for the given sample. Tests for randomness.
    /// ### Important Note ###
    /// It is important that the data are numerical. To recode non-numerical data follow the procedure as described below.<br/>
    ///
    /// ````
    /// Suppose the original data is a string containing only "H" and "L":
    /// HLHHLHHLHLLHLHHL
    /// Setting "H" = 1 and "L" = 3 results in the recoded sequence:
    /// 1311311313313113
    /// In this case a cutting point of 2 must be used.
    /// Setting "H" = 1 and "L" = 2 results in the recoded sequence:
    /// 1211211212212112
    /// In this case a cutting point of 1.5 must be used.
    /// ````
    ///
    /// - Parameter data: Array<Double>
    /// - Parameter alpha: Alpha
    /// - Parameter useCuttingPoint: SSRunsTestCuttingPoint.median || SSRunsTestCuttingPoint.mean || SSRunsTestCuttingPoint.mode || SSRunsTestCuttingPoint.userDefined
    /// - Parameter cP: A user defined cutting point. Must not be nil if SSRunsTestCuttingPoint.userDefined is set
    /// - Throws: SSSwiftyStatsError iff data.sampleSize < 2
    public class func runsTest(data: SSExamine<Double>!, alpha: Double!, useCuttingPoint useCP: SSRunsTestCuttingPoint, userDefinedCuttingPoint cuttingPoint: Double?, alternative: SSAlternativeHypotheses) throws -> SSRunsTestResult {
        if data.sampleSize < 2 {
            os_log("sample size is expected to be >= 2", log: log_stat, type: .error)
            throw SSSwiftyStatsError.init(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        var diff = Array<Double>()
        let elements = data.elementsAsArray(sortOrder: .raw)!
        var dtemp: Double = 0.0
        var n2: Double = 0.0
        var n1: Double = 0.0
        var r: Int = 1
        var cp: Double = 0.0
        //        var isPrevPos: Bool
        switch useCP {
        case .mean:
            cp = data.arithmeticMean!
        case .median:
            cp = data.median!
        case .mode:
            if let modes = data.commonest {
                cp = modes.sorted(by: {$0 > $1})[0]
            }
        case .userDefined:
            if let _ = cuttingPoint {
                cp = cuttingPoint!
            }
            else {
                os_log("no user defined cutting point specified", log: log_stat, type: .error)
                throw SSSwiftyStatsError.init(type: .invalidArgument, file: #file, line: #line, function: #function)
            }
        }
        var RR = 1
        var s = (elements.first! - cp).sign
        var i = 0
        for element in elements {
            dtemp = element - cp
            diff.append(dtemp)
            if dtemp.sign != s {
                s = dtemp.sign
                RR += 1
            }
            i += 1
            if dtemp >= 0.0 {
                n2 += 1.0
            }
            else {
                n1 += 1.0
            }
        }
        /* keep this for historical reasons ;-)
         for d in diff {
         if d.sign != s {
         s = d.sign
         RR += 1
         }
         i += 1
         }
         */
        r = RR
        dtemp = n1 + n2
        let sigma = sqrt((2.0 * n2 * n1 * (2.0 * n2 * n1 - n1 - n2)) / ((dtemp * dtemp * (n2 + n1 - 1.0))))
        let mean = (2.0 * n2 * n1) / dtemp + 1.0
        var z: Double = 0.0
        dtemp = Double(r) - mean
        let pExact: Double = Double.nan
        var pAsymp: Double = 0.0
        var cv: Double
        do {
            cv = try SSProbabilityDistributions.quantileStandardNormalDist(p: 1 - alpha / 2.0)
        }
        catch {
            throw error
        }
        //        if n1 + n2 >= 60 {
        z = dtemp / sigma
        //        }
        //        else {
        //            z = (dtemp - 0.5) / sigma
        //        }
        switch alternative {
        case .twoSided:
            pAsymp = 2.0 * SSProbabilityDistributions.cdfStandardNormalDist(u: -fabs(z))
        case .less:
            pAsymp = SSProbabilityDistributions.cdfStandardNormalDist(u: z)
        case .greater:
            pAsymp = 1.0 - SSProbabilityDistributions.cdfStandardNormalDist(u: z)
        }
        //        if pAsymp > 0.5 {
        //            pAsymp = (1.0 - pAsymp) * 2.0
        //        }
        //        else {
        //            pAsymp *= 2.0
        //        }
        //        if n1 + n2 <= 30 {
        //            if r % 2 == 0 {
        //                var rr = 2
        //                var sum = 0.0
        //                var q = 0.0
        //                while rr <= r {
        //                    q = Double(rr) / 2.0
        //                    sum += binomial2(n1 - 1.0, q - 1.0) * binomial2(n2 - 1.0,q - 1)
        //                    rr += 1
        //                }
        //                pExact = 2.0 * sum / binomial2((n1 + n2), n1)
        //            }
        //            else {
        //                var rr = 2
        //                var sum = 0.0
        //                var q = 0.0
        //                while rr <= r {
        //                    q = Double(rr - 1) / 2.0
        //                    sum += (binomial2(n1 - 1.0, q) * binomial2(n2 - 1.0, q - 1) / 2.0) + binomial2(n1 - 1.0, q - 1.0) * binomial2(n2 - 1.0, q)
        //                    rr += 1
        //                }
        //                pExact = sum / binomial2((n1 + n2), n1)
        //            }
        //        }
        var result = SSRunsTestResult()
        result.nGTEcp = n2
        result.nLTcp = n1
        result.nRuns = Double(r)
        result.zStat = z
        result.pValueExact = pExact
        result.pValueAsymp = pAsymp
        result.cp = cp
        result.diffs = diff
        result.criticalValue = cv
        result.randomness = fabs(z) <= cv
        return result
    }
    

}
